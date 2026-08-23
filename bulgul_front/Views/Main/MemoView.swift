import SwiftUI

private struct DummyMemo: Identifiable {
    let id = UUID()
    let title: String
    let preview: String
    let date: String
}

private let dummyMemos: [DummyMemo] = [
    DummyMemo(title: "로고 색상 후보", preview: "메인 블루 #2563EB, 포인트 컬러는 좀 더 채도 낮춰보기", date: "8월 22일"),
    DummyMemo(title: "클라이언트 미팅 메모", preview: "다음 시안은 그리드 간격 좁혀서 다시 보내드리기로 함", date: "8월 21일"),
    DummyMemo(title: "아이콘 참고 링크", preview: "https://example.com/icon-set 여기서 스타일 참고하면 좋을듯", date: "8월 19일"),
    DummyMemo(title: "폰트 후보", preview: "Pretendard vs 노토산스, 본문은 Pretendard로 확정", date: "8월 15일"),
]

struct MemoView: View {
    @Binding var token: String?
    @Binding var currentScreen: MenuScreen

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

            Divider()
                .padding(.horizontal)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(dummyMemos) { memo in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(memo.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)

                                Spacer()

                                Text(memo.date)
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
