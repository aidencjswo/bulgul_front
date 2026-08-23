//
//  bulgul_frontApp.swift
//  bulgul_front
//
//  Created by 안상영 on 7/27/26.
//

import SwiftUI
import ServiceManagement
import Sparkle

@main
struct MainApp : App {

    @State private var token : String? = nil
    @State private var updaterController: SPUStandardUpdaterController

    private let keychainTokenStore = KeychainTokenStore()

    init() {
        // 시스템 언어와 무관하게 항상 한글 UI(Sparkle 업데이트 창 포함)로 표시
        // Sparkle이 언어 리소스를 고르기 전에 먼저 설정되어야 함
        UserDefaults.standard.set(["ko"], forKey: "AppleLanguages")

        // 앱 시작 시 Keychain에서 토큰 로드
        let savedToken = keychainTokenStore.load()
        _token = State(initialValue: savedToken)
        _updaterController = State(initialValue: SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil))

        // 컴퓨터를 껐다 켜도(로그인 시) 앱이 자동으로 실행되도록 등록
        if SMAppService.mainApp.status != .enabled {
            try? SMAppService.mainApp.register()
        }
    }

    var body : some Scene {

        // .menu 스타일은 진짜 NSMenu라서, .window 스타일과 달리
        // "메뉴바 자동 숨김" 설정에 영향을 안 받음
        MenuBarExtra("불굴의 디자인", image: "menuBarIcon") {
            MenuBarDropdownView(updaterController: updaterController)
        }
        .menuBarExtraStyle(.menu)

        // 실제 화면(로그인/목록/ChatGPT 등)은 일반 창으로 따로 띄움
        Window("불굴의 디자인", id: "main") {
            ContentView(token: $token)
        }
        .windowResizability(.contentSize)

    }

}

private struct MenuBarDropdownView: View {
    @Environment(\.openWindow) private var openWindow
    let updaterController: SPUStandardUpdaterController

    var body: some View {
        Button("열기") {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "main")
        }

        Button("업데이트 확인...") {
            updaterController.checkForUpdates(nil)
        }

        Divider()

        Button("종료") {
            NSApplication.shared.terminate(nil)
        }
    }
}
