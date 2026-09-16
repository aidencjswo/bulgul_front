//
//  bulgul_frontApp.swift
//  bulgul_front
//
//  Created by 안상영 on 7/27/26.
//

import SwiftUI
import ServiceManagement
import Sparkle
import AppKit
import Combine

// MenuBarExtra/Window scene/SMAppService는 macOS 13.0부터 생긴 API라
// macOS 12(Monterey)까지 지원하기 위해 AppKit(NSStatusItem/NSWindow)으로 직접 구현함
@main
struct MainApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // SwiftUI App은 Scene이 최소 하나 필요한데, 실제 UI는 전부 AppDelegate가
        // NSStatusItem/NSWindow로 직접 관리하므로 아무것도 표시 안 되는 빈 Scene만 둠
        Settings {
            EmptyView()
        }
    }
}

private class AppState: ObservableObject {
    @Published var token: String?
}

private struct RootView: View {
    @ObservedObject fileprivate var appState: AppState

    var body: some View {
        ContentView(token: $appState.token)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var mainWindow: NSWindow?
    private var updaterController: SPUStandardUpdaterController!
    private let updaterDelegate = UpdaterDelegate()
    private let keychainTokenStore = KeychainTokenStore()
    private let appState = AppState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 시스템 언어와 무관하게 항상 한글 UI(Sparkle 업데이트 창 포함)로 표시
        // Sparkle이 언어 리소스를 고르기 전에 먼저 설정되어야 함
        UserDefaults.standard.set(["ko"], forKey: "AppleLanguages")

        appState.token = keychainTokenStore.load()
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: updaterDelegate, userDriverDelegate: nil)

        // 컴퓨터를 껐다 켜도(로그인 시) 앱이 자동으로 실행되도록 등록 (macOS 13+)
        if #available(macOS 13.0, *) {
            if SMAppService.mainApp.status != .enabled {
                try? SMAppService.mainApp.register()
            }
        }

        setupStatusItem()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            let image = NSImage(named: "menuBarIcon")
            image?.isTemplate = true
            button.image = image
        }

        let menu = NSMenu()

        let openItem = NSMenuItem(title: "열기", action: #selector(openMainWindow), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)

        let updateItem = NSMenuItem(title: "업데이트 확인...", action: #selector(checkForUpdates), keyEquivalent: "")
        updateItem.target = self
        menu.addItem(updateItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "종료", action: #selector(quitApp), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)

        if let mainWindow {
            mainWindow.makeKeyAndOrderFront(nil)
            return
        }

        let hosting = NSHostingController(rootView: RootView(appState: appState))
        let window = NSWindow(contentViewController: hosting)
        window.title = "불굴의 디자인"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        mainWindow = window
    }

    @objc private func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
