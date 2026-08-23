import SwiftUI
import UniformTypeIdentifiers

struct FileManagementView: View {
    @Binding var token: String?
    @Binding var currentScreen: MenuScreen

    @State private var files: [FileInfo] = []
    @State private var isLoading = true
    @State private var isUploading = false
    @State private var showFileImporter = false
    @State private var statusMessage = ""

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
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(files) { file in
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
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
        .frame(minWidth: 300, maxWidth: 500, minHeight: 400, maxHeight: 600)
        .task {
            await loadFiles()
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.item]) { result in
            switch result {
            case .success(let url):
                uploadFile(url)
            case .failure(let error):
                statusMessage = "⚠️ 파일 선택 실패: \(error.localizedDescription)"
            }
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
        statusMessage = ""

        let didStartAccessing = url.startAccessingSecurityScopedResource()

        Task {
            do {
                try await FileService.shared.uploadFile(fileURL: url)
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
