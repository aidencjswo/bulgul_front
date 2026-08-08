import SwiftUI

// 팝오버 안에서 전환될 화면 상태
enum MenuScreen: Equatable {
    case menu
    case login
    case signup
    case mainContent
    case detailConents(TipsResponse)
    case createTip
    case chatGPT

    static func == (lhs: MenuScreen, rhs: MenuScreen) -> Bool {
        switch (lhs, rhs) {
        case (.menu, .menu),
             (.login, .login),
             (.signup, .signup),
             (.mainContent, .mainContent),
             (.createTip, .createTip),
             (.chatGPT, .chatGPT):
            return true
        case (.detailConents(let lhsTip), .detailConents(let rhsTip)):
            return lhsTip.id == rhsTip.id
        default:
            return false
        }
    }
}

struct ContentView: View {
    @Binding var token : String?
    @State private var currentScreen: MenuScreen

    // ChatGPT 웹뷰의 세션(로그인, 스크롤 위치 등)이 화면 전환 후에도 유지되도록
    // ContentView 레벨에서 계속 살아있게 함
    @StateObject private var chatGPTCoordinator = DownloadCoordinator()

    init(token: Binding<String?>) {
        self._token = token
        // 로그인 안 된 상태면 메뉴보다 로그인 화면을 먼저 보여줌
        self._currentScreen = State(initialValue: token.wrappedValue?.isEmpty == false ? .menu : .login)
    }

    var body: some View {
        Group {
            switch currentScreen {
            case .menu:
                MenuButtonsView(token: $token, currentScreen: $currentScreen)
            case .login:
                LoginFormView(token: $token, currentScreen: $currentScreen)
            case .signup:
                SignUpFormView(token: $token, currentScreen: $currentScreen)
            case .mainContent:
                MainContentsView(token: $token, currentScreen: $currentScreen)
            case .detailConents(let selectedTip):
                DetailContentsView(token: $token, currentScreen: $currentScreen, selectedTip: selectedTip)
            case .createTip:
                AddTipFormView(token: $token, currentScreen: $currentScreen)
            case .chatGPT:
                ChatGPTWebView(currentScreen: $currentScreen, coordinator: chatGPTCoordinator)
            }
        }
        // 토큰이 만료(401)되면 어느 화면에 있든 로그인 전 상태로 되돌림
        .onReceive(NotificationCenter.default.publisher(for: .authTokenExpired)) { _ in
            token = nil
            currentScreen = .login
        }
    }

}
