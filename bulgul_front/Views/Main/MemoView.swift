import SwiftUI

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

                // 오른쪽 여백 (대칭을 위해)
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .opacity(0)
            }
            .padding(.horizontal)
            .padding(.top)

            Divider()
                .padding(.horizontal)

            Spacer()

            Text("메모 기능 준비 중입니다")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(minWidth: 300, maxWidth: 500, minHeight: 400, maxHeight: 600)
    }
}

#Preview {
    MemoView(token: .constant("preview"), currentScreen: .constant(.memo))
}
