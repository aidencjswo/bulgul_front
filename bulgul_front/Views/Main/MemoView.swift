import SwiftUI

private struct DummyMemo: Identifiable {
    let id = UUID()
    let title: String
    let preview: String
    let date: Date
}

private func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
    Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
}

private let dummyMemos: [DummyMemo] = [
    DummyMemo(title: "로고 색상 후보", preview: "메인 블루 #2563EB, 포인트 컬러는 좀 더 채도 낮춰보기", date: makeDate(2026, 8, 22)),
    DummyMemo(title: "클라이언트 미팅 메모", preview: "다음 시안은 그리드 간격 좁혀서 다시 보내드리기로 함", date: makeDate(2026, 8, 21)),
    DummyMemo(title: "아이콘 참고 링크", preview: "https://example.com/icon-set 여기서 스타일 참고하면 좋을듯", date: makeDate(2026, 8, 19)),
    DummyMemo(title: "폰트 후보", preview: "Pretendard vs 노토산스, 본문은 Pretendard로 확정", date: makeDate(2026, 8, 15)),
]

private let memoDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "M월 d일"
    return formatter
}()

struct MemoView: View {
    @Binding var token: String?
    @Binding var currentScreen: MenuScreen

    @State private var searchText: String = ""
    @State private var selectedDate: Date? = nil
    @State private var isPickingDate: Bool = false

    private var filteredMemos: [DummyMemo] {
        dummyMemos.filter { memo in
            let matchesSearch = searchText.isEmpty
                || memo.title.localizedCaseInsensitiveContains(searchText)
                || memo.preview.localizedCaseInsensitiveContains(searchText)

            let matchesDate = selectedDate == nil
                || Calendar.current.isDate(memo.date, inSameDayAs: selectedDate!)

            return matchesSearch && matchesDate
        }
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

                Text("메모")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Button(action: {}) {
                    Image(systemName: "plus")
                        .font(.title3)
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top)

            // 검색 바 + 날짜 필터 (한 줄)
            HStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("검색...", text: $searchText)
                        .textFieldStyle(.plain)

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)

                Button(action: {
                    isPickingDate.toggle()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                        Text(selectedDate.map { memoDateFormatter.string(from: $0) } ?? "날짜")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 10)
                    .frame(height: 30)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                    .fixedSize()
                }
                .buttonStyle(.plain)
                .popover(isPresented: $isPickingDate) {
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { selectedDate ?? Date() },
                            set: { selectedDate = $0 }
                        ),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding()
                }

                if selectedDate != nil {
                    Button(action: {
                        selectedDate = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            Divider()
                .padding(.horizontal)

            ScrollView {
                VStack(spacing: 10) {
                    if filteredMemos.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "note.text")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                                .padding(.top, 40)

                            Text("조건에 맞는 메모가 없습니다")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        ForEach(filteredMemos) { memo in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(memo.title)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)

                                    Spacer()

                                    Text(memoDateFormatter.string(from: memo.date))
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }

                                Text(memo.preview)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(12)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .frame(minWidth: 300, maxWidth: 500, minHeight: 400, maxHeight: 600)
    }
}

#Preview {
    MemoView(token: .constant("preview"), currentScreen: .constant(.memo))
}
