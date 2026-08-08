import SwiftUI

// 📌 구조체(struct)로 선언해야 @Binding 사용이 가능합니다.
struct MenuButtonsView: View {
    @Binding var token: String?
    @Binding var currentScreen: MenuScreen
    
    private let keychainTokenStore = KeychainTokenStore()
    
    var body: some View {
        VStack(spacing: 0) {
            // 이 화면은 로그인 상태에서만 보임 (로그인 전이면 onAppear에서 바로 .login으로 보냄)
            VStack(spacing: 0) {
                MenuItemButton(icon: "list.bullet.rectangle", title: "단축키 조회") {
                    currentScreen = .mainContent
                }

                Divider()
                    .padding(.leading, 40)

                MenuItemButton(icon: "bubble.left.and.text.bubble.right", title: "ChatGPT") {
                    currentScreen = .chatGPT
                }

                Divider()
                    .padding(.leading, 40)

                MenuItemButton(icon: "plus.circle", title: "팁 추가") {
                    currentScreen = .createTip
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal, 8)
            .padding(.top, 8)

            Spacer()

            // 하단 - 로그아웃과 종료
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 1)
                .padding(.vertical, 8)

            HStack(spacing: 8) {
                // 로그아웃
                Button(action: {
                    keychainTokenStore.delete()
                    token = nil
                    currentScreen = .login
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.square")
                            .font(.system(size: 13))
                        Text("로그아웃")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)

                // 종료
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "power")
                            .font(.system(size: 13))
                        Text("종료")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .frame(minWidth: 300, maxWidth: 500)
        .padding(.vertical, 8)
        .onAppear {
            // 로그인 안 된 상태로 이 화면에 오면 바로 로그인 화면으로 보냄
            if token?.isEmpty != false {
                currentScreen = .login
            }
        }
    }
}

// 메뉴 아이템 버튼 컴포넌트
struct MenuItemButton: View {
    let icon: String
    let title: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isDestructive ? .red : .primary)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(isDestructive ? .red : .primary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
