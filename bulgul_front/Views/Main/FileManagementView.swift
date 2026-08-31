import SwiftUI
import UniformTypeIdentifiers

private enum FileDisplayMode: String, CaseIterable {
    case detail = "자세히보기"
    case preview = "미리보기"
    case calendar = "달력"
}

// 세션 동안 한 번 받은 썸네일은 다시 안 받도록 메모리 캐시
private class ThumbnailCache {
    static let shared = NSCache<NSString, NSImage>()
}

struct FileManagementView: View {
    @Binding var token: String?
    @Binding var currentScreen: MenuScreen

    @State private var displayMode: FileDisplayMode = .detail
    @State private var files: [FileInfo] = []
    @State private var isLoading = true
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var showFileImporter = false
    @State private var statusMessage = ""
    @State private var isDropTargeted = false
    @State private var pendingDuplicateURL: URL? = nil
    @State private var showDuplicateAlert = false
    @State private var pendingDeleteFile: FileInfo? = nil
    @State private var showDeleteConfirm = false
    @State private var searchText = ""
    @State private var selectedDateFilter: Date? = nil
    @State private var calendarMonth = Date()
    @State private var memoFile: FileInfo? = nil
    @State private var storageUsage: StorageUsage? = nil

    private var filteredFiles: [FileInfo] {
        var result = files
        if !searchText.isEmpty {
            result = result.filter { $0.filename.localizedCaseInsensitiveContains(searchText) }
        }
        if let selectedDateFilter {
            let calendar = Calendar.current
            result = result.filter {
                calendar.isDate(Date(timeIntervalSince1970: $0.modifiedAt), inSameDayAs: selectedDateFilter)
            }
        }
        return result
    }

    // 파일이 존재하는 날짜(하루 단위) 집합 — 달력에 표시 여부 판단용
    private var datesWithFiles: Set<Date> {
        let calendar = Calendar.current
        return Set(files.map { calendar.startOfDay(for: Date(timeIntervalSince1970: $0.modifiedAt)) })
    }

    // 첨부 날짜(하루 단위)별로 묶어서 최신 날짜가 위로 오도록 정렬
    private var groupedFiles: [(day: Date, files: [FileInfo])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: filteredFiles) { file in
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

            Picker("", selection: $displayMode) {
                ForEach(FileDisplayMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if displayMode != .calendar {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("파일명 검색", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .padding(.horizontal)
            }

            if let selectedDateFilter {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                    Text(dayFormatter.string(from: selectedDateFilter))
                    Spacer()
                    Button("전체보기") { self.selectedDateFilter = nil }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            }

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
            } else if displayMode == .calendar {
                CalendarModeView(datesWithFiles: datesWithFiles, month: $calendarMonth) { date in
                    selectedDateFilter = date
                    displayMode = .detail
                }
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
            } else if filteredFiles.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("검색 결과가 없습니다")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else if displayMode == .detail {
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
                                        }
                                        .padding(12)
                                        .background(Color(NSColor.controlBackgroundColor))
                                        .cornerRadius(10)
                                        .contextMenu {
                                            Button("다운로드") { downloadFile(file) }
                                            Button("메모") { memoFile = file }
                                            Button("삭제", role: .destructive) { requestDelete(file) }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .frame(maxHeight: 400)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(groupedFiles, id: \.day) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(dayFormatter.string(from: group.day))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 84, maximum: 84), spacing: 12)], spacing: 12) {
                                    ForEach(group.files) { file in
                                        FileThumbnailCell(file: file, onDownload: { downloadFile(file) }, onMemo: { memoFile = file }, onDelete: { requestDelete(file) })
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .frame(maxHeight: 400)
            }

            if let storageUsage {
                Divider()
                    .padding(.horizontal)

                VStack(spacing: 4) {
                    ProgressView(value: storageUsageFraction(storageUsage))
                    Text(storageUsageText(storageUsage))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .frame(minWidth: 300, maxWidth: 500)
        .fixedSize(horizontal: false, vertical: true)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.accentColor, lineWidth: 2)
                .opacity(isDropTargeted ? 1 : 0)
                .padding(4)
                .allowsHitTesting(false)
        )
        .task {
            await loadFiles()
            await loadStorageUsage()
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
        .alert("파일을 삭제하시겠습니까?", isPresented: $showDeleteConfirm, presenting: pendingDeleteFile) { file in
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                deleteFile(file)
            }
        } message: { file in
            Text("\"\(file.filename)\"을(를) 삭제하면 복구할 수 없습니다.")
        }
        .sheet(item: $memoFile) { file in
            FileMemoEditorView(file: file)
        }
    }

    private func requestDelete(_ file: FileInfo) {
        pendingDeleteFile = file
        showDeleteConfirm = true
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

    private func loadStorageUsage() async {
        storageUsage = try? await FileService.shared.getStorageUsage()
    }

    private func storageUsageFraction(_ usage: StorageUsage) -> Double {
        guard let limit = usage.limit, limit > 0 else { return 0 }
        return min(Double(usage.used) / Double(limit), 1.0)
    }

    private func storageUsageText(_ usage: StorageUsage) -> String {
        let usedText = ByteCountFormatter.string(fromByteCount: usage.used, countStyle: .file)
        guard let limit = usage.limit else { return "\(usedText) 사용 중" }
        let limitText = ByteCountFormatter.string(fromByteCount: limit, countStyle: .file)
        return "\(usedText) / \(limitText) 사용 중"
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
                await loadStorageUsage()
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
                await loadStorageUsage()
            } catch {
                await MainActor.run {
                    statusMessage = "⚠️ 삭제 실패: \(error.localizedDescription)"
                }
            }
        }
    }
}

// 미리보기 모드의 그리드 셀 (이미지 파일이면 썸네일, 아니면 아이콘)
private struct FileThumbnailCell: View {
    let file: FileInfo
    let onDownload: () -> Void
    let onMemo: () -> Void
    let onDelete: () -> Void

    @State private var thumbnail: NSImage?
    @State private var isLoading = false

    private var isImage: Bool {
        let ext = (file.filename as NSString).pathExtension.lowercased()
        return ["png", "jpg", "jpeg", "gif", "heic", "bmp", "tiff", "webp"].contains(ext)
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .frame(width: 80, height: 80)

                if let thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else if isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                } else {
                    Image(systemName: isImage ? "photo" : "doc")
                        .font(.system(size: 26))
                        .foregroundColor(.secondary)
                }
            }

            Text(file.filename)
                .font(.system(size: 10))
                .lineLimit(1)
                .frame(width: 80)
        }
        .contextMenu {
            Button("다운로드", action: onDownload)
            Button("메모", action: onMemo)
            Button("삭제", role: .destructive, action: onDelete)
        }
        .task {
            guard isImage, thumbnail == nil else { return }

            if let cached = ThumbnailCache.shared.object(forKey: file.filename as NSString) {
                thumbnail = cached
                return
            }

            isLoading = true
            // 서버에 미리 만들어둔 작은 썸네일을 먼저 시도하고, 없으면(구버전 파일 등) 원본 전체를 받음
            if let data = try? await FileService.shared.getThumbnail(filename: file.filename),
               let image = NSImage(data: data) {
                thumbnail = image
                ThumbnailCache.shared.setObject(image, forKey: file.filename as NSString)
            } else if let data = try? await FileService.shared.downloadFile(filename: file.filename),
                      let image = NSImage(data: data) {
                thumbnail = image
                ThumbnailCache.shared.setObject(image, forKey: file.filename as NSString)
            }
            isLoading = false
        }
    }
}

// 파일 하나에 대한 메모를 보고 수정하는 시트
private struct FileMemoEditorView: View {
    let file: FileInfo

    @Environment(\.dismiss) private var dismiss
    @State private var memoText = ""
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var statusMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(file.filename)
                .font(.headline)
                .lineLimit(1)

            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                TextEditor(text: $memoText)
                    .font(.system(size: 13))
                    .frame(minHeight: 160)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                    )
            }

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Spacer()
                Button("취소") { dismiss() }
                Button("저장") { save() }
                    .disabled(isLoading || isSaving)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 360, height: 280)
        .task {
            do {
                memoText = try await FileService.shared.getMemo(filename: file.filename)
            } catch {
                statusMessage = "⚠️ 메모를 불러오지 못했습니다."
            }
            isLoading = false
        }
    }

    private func save() {
        isSaving = true
        Task {
            do {
                try await FileService.shared.saveMemo(filename: file.filename, memo: memoText)
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run {
                    isSaving = false
                    statusMessage = "⚠️ 저장 실패: \(error.localizedDescription)"
                }
            }
        }
    }
}

// 달력 한 칸을 정사각형으로 만들기 위해 실제 렌더링된 열 폭을 측정해서 전달
private struct CalendarCellWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 36
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// 달력 6행×7열 내부 격자선 — 셀마다 개별로 테두리를 그리면 열 경계가 서브픽셀 위치에
// 걸려 사라지는 경우가 있어, 그리드 전체 크기를 기준으로 한 번에 계산해서 그린다.
private struct CalendarGridLines: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let cellWidth = geo.size.width / 7
                let cellHeight = geo.size.height / 6
                for col in 1..<7 {
                    let x = cellWidth * CGFloat(col)
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                }
                for row in 1..<6 {
                    let y = cellHeight * CGFloat(row)
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
            }
            .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5)
        }
    }
}

// 달력 모드: 파일이 있는 날짜를 표시하고, 클릭하면 자세히보기로 필터링
private struct CalendarModeView: View {
    let datesWithFiles: Set<Date>
    @Binding var month: Date
    let onSelectDate: (Date) -> Void

    private let calendar = Calendar.current
    private let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]

    @State private var cellSize: CGFloat = 36

    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        return formatter
    }

    // 이번 달 날짜들을 요일에 맞춰 앞뒤에 빈 칸(nil)을 채워서 항상 6줄(42칸)로 반환
    private var daysInGrid: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let dayCount = calendar.range(of: .day, in: .month, for: month)?.count ?? 0

        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        for offset in 0..<dayCount {
            if let date = calendar.date(byAdding: .day, value: offset, to: monthInterval.start) {
                days.append(date)
            }
        }
        while days.count < 42 {
            days.append(nil)
        }
        return days
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Text(monthFormatter.string(from: month))
                    .font(.system(size: 14, weight: .semibold))

                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.primary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)

            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 6)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                ForEach(Array(daysInGrid.enumerated()), id: \.offset) { _, date in
                    if let date {
                        let hasFiles = datesWithFiles.contains(calendar.startOfDay(for: date))
                        Button(action: { if hasFiles { onSelectDate(date) } }) {
                            VStack(spacing: 2) {
                                Text("\(calendar.component(.day, from: date))")
                                    .font(.system(size: 12, weight: hasFiles ? .semibold : .regular))
                                Circle()
                                    .fill(hasFiles ? Color.accentColor : Color.clear)
                                    .frame(width: 4, height: 4)
                            }
                            .frame(maxWidth: .infinity, minHeight: cellSize)
                            .background(hasFiles ? Color.accentColor.opacity(0.12) : Color.clear)
                        }
                        .buttonStyle(.plain)
                        .disabled(!hasFiles)
                    } else {
                        Color.clear.frame(maxWidth: .infinity, minHeight: cellSize)
                    }
                }
            }
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: CalendarCellWidthKey.self, value: geo.size.width / 7)
                }
            )
            .background(CalendarGridLines())
            .onPreferenceChange(CalendarCellWidthKey.self) { cellSize = $0 }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 4)
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: month) {
            month = newMonth
        }
    }
}

#Preview {
    FileManagementView(token: .constant("preview"), currentScreen: .constant(.fileManagement))
}
