import SwiftUI
import UniformTypeIdentifiers

struct FileManagementView: View {
    @Binding var token: String?
    @Binding var currentScreen: MenuScreen

    @State private var files: [FileInfo] = []
    @State private var isLoading = true
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var showFileImporter = false
    @State private var statusMessage = ""
    @State private var isDropTargeted = false
    @State private var pendingDuplicateURL: URL? = nil
    @State private var showDuplicateAlert = false

    // 첨부 날짜(하루 단위)별로 묶어서 최신 날짜가 위로 오도록 정렬
    private var groupedFiles: [(day: Date, files: [FileInfo])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: files) { file in
            calendar.startOfDay(for: Date(timeIntervalSince1970: file.modifiedAt))
        }
        return groups
            .map { (day: $0.key, files: $0.value.sorted { $0.modifiedAt > $1.modifiedAt }) }
            .sorted { $0.day > $1.day }
    }

    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter
    }

    var body: some View {
        VStack(spacing: 12) {
            // 헤더
            HStack {
                Button(action: {
                    currentScreen = .menu
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer()

                Text("파일관리")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Button(action: {
                    showFileImporter = true
                }) {
                    if isUploading {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 32, height: 32)
                    } else {
                        Image(systemName: "plus")
                            .font(.title3)
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .buttonStyle(.plain)
                .disabled(isUploading)
            }
            .padding(.horizontal)
            .padding(.top)

            if isUploading {
                VStack(spacing: 4) {
                    ProgressView(value: uploadProgress)
                    Text("\(Int(uploadProgress * 100))% 업로드 중...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()
                .padding(.horizontal)

            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if files.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "folder")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("저장된 파일이 없습니다")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("여기로 파일을 드래그하면 업로드됩니다")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(groupedFiles, id: \.day) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(dayFormatter.string(from: group.day))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)

                                VStack(spacing: 10) {
                                    ForEach(group.files) { file in
                                        HStack(spacing: 12) {
                                            Image(systemName: "doc")
                                                .foregroundColor(.secondary)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(file.filename)
                                                    .font(.system(size: 13, weight: .medium))
                                                    .lineLimit(1)
                                                Text(formattedSize(file.size))
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.secondary)
                                            }

                                            Spacer()

                                            Button(action: {
                                                downloadFile(file)
                                            }) {
                                                Image(systemName: "arrow.down.circle")
                                                    .foregroundColor(.secondary)
                                            }
                                            .buttonStyle(.plain)

                                            Button(action: {
                                                deleteFile(file)
                                            }) {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(12)
                                        .background(Color(NSColor.controlBackgroundColor))
                                        .cornerRadius(10)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
        .frame(minWidth: 300, maxWidth: 500, minHeight: 400, maxHeight: 600)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.accentColor, lineWidth: 2)
                .opacity(isDropTargeted ? 1 : 0)
                .padding(4)
                .allowsHitTesting(false)
        )
        .task {
            await loadFiles()
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.item]) { result in
            switch result {
            case .success(let url):
                handleFileSelected(url)
            case .failure(let error):
                statusMessage = "⚠️ 파일 선택 실패: \(error.localizedDescription)"
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            for provider in providers {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url {
                        DispatchQueue.main.async {
                            handleFileSelected(url)
                        }
                    }
                }
            }
            return true
        }
        .alert("같은 이름의 파일이 있습니다", isPresented: $showDuplicateAlert, presenting: pendingDuplicateURL) { url in
            Button("취소", role: .cancel) {}
            Button("그래도 업로드") {
                uploadFile(url)
            }
        } message: { url in
            Text("\"\(url.lastPathComponent)\"와 같은 이름의 파일이 이미 있습니다. 그래도 업로드하면 파일명에 번호가 붙어서 저장됩니다.")
        }
    }

    private func handleFileSelected(_ url: URL) {
        if files.contains(where: { $0.filename == url.lastPathComponent }) {
            pendingDuplicateURL = url
            showDuplicateAlert = true
        } else {
            uploadFile(url)
        }
    }

    private func formattedSize(_ bytes: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    private func loadFiles() async {
        isLoading = true
        do {
            files = try await FileService.shared.listFiles()
        } catch {
            statusMessage = "⚠️ 파일 목록을 불러오지 못했습니다."
        }
        isLoading = false
    }

    private func uploadFile(_ url: URL) {
        isUploading = true
        uploadProgress = 0
        statusMessage = ""

        let didStartAccessing = url.startAccessingSecurityScopedResource()

        Task {
            do {
                try await FileService.shared.uploadFile(fileURL: url) { progress in
                    uploadProgress = progress
                }
                if didStartAccessing { url.stopAccessingSecurityScopedResource() }
                await MainActor.run {
                    isUploading = false
                }
                await loadFiles()
            } catch {
                if didStartAccessing { url.stopAccessingSecurityScopedResource() }
                await MainActor.run {
                    isUploading = false
                    statusMessage = "⚠️ 업로드 실패: \(error.localizedDescription)"
                }
            }
        }
    }

    private func downloadFile(_ file: FileInfo) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = file.filename
        panel.begin { response in
            guard response == .OK, let destination = panel.url else { return }

            Task {
                do {
                    let data = try await FileService.shared.downloadFile(filename: file.filename)
                    try data.write(to: destination)
                } catch {
                    await MainActor.run {
                        statusMessage = "⚠️ 다운로드 실패: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    private func deleteFile(_ file: FileInfo) {
        Task {
            do {
                try await FileService.shared.deleteFile(filename: file.filename)
                await loadFiles()
            } catch {
                await MainActor.run {
                    statusMessage = "⚠️ 삭제 실패: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    FileManagementView(token: .constant("preview"), currentScreen: .constant(.fileManagement))
}
