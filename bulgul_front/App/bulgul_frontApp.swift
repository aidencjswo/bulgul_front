//
//  bulgul_frontApp.swift
//  bulgul_front
//
//  Created by 안상영 on 7/27/26.
//

import SwiftUI

@main
struct MainApp : App {

    @State private var token : String? = nil

    private let keychainTokenStore = KeychainTokenStore()

    init() {
        // 앱 시작 시 Keychain에서 토큰 로드
        let savedToken = keychainTokenStore.load()
        _token = State(initialValue: savedToken)
    }

    var body : some Scene {

        // .menu 스타일은 진짜 NSMenu라서, .window 스타일과 달리
        // "메뉴바 자동 숨김" 설정에 영향을 안 받음
        MenuBarExtra("bulgul", systemImage: "star.fill") {
            MenuBarDropdownView()
        }
        .menuBarExtraStyle(.menu)

        // 실제 화면(로그인/목록/ChatGPT 등)은 일반 창으로 따로 띄움
        Window("bulgul", id: "main") {
            ContentView(token: $token)
        }
        .windowResizability(.contentSize)

    }

}

private struct MenuBarDropdownView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("열기") {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "main")
        }

        Divider()

        Button("종료") {
            NSApplication.shared.terminate(nil)
        }
    }
}
