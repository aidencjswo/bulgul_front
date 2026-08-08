import SwiftUI
import WebKit
import Combine
import UniformTypeIdentifiers

struct ChatGPTWebView: View {
    @Binding var currentScreen: MenuScreen
    @ObservedObject var coordinator: DownloadCoordinator

    var body: some View {
        VStack(spacing: 0) {
            // 간소화된 헤더
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
                
                Text("ChatGPT")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                // 이미지 다운로드 버튼
                Button(action: {
                    coordinator.downloadCurrentImage()
                }) {
                    Image(systemName: "arrow.down.circle")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                .help("마지막으로 본 이미지 다운로드")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            // 웹뷰
            DownloadableWebView(url: URL(string: "https://chat.openai.com")!, coordinator: coordinator)
        }
        .frame(minWidth: 600, maxWidth: 800, minHeight: 500, maxHeight: 700)
    }
}

// 다운로드 가능한 WebKit WKWebView
class DownloadCoordinator: NSObject, ObservableObject, WKNavigationDelegate, WKDownloadDelegate, WKUIDelegate, WKScriptMessageHandler {
    @Published var lastImageURL: String?
    var webView: WKWebView?
    
    // JavaScript 메시지 핸들러
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "imageContext",
              let dict = message.body as? [String: Any],
              let src = dict["src"] as? String else { return }

        lastImageURL = src

        // 우클릭(contextmenu)인 경우: 기본 컨텍스트 메뉴는 JS 쪽에서 이미 막았으므로
        // 여기서 커스텀 메뉴를 대신 띄움 (WebKit 기본 "Download Image"는 이 앱 샌드박스에서 실패함)
        if dict["type"] as? String == "contextmenu",
           let webView = webView,
           let x = dict["x"] as? Double,
           let y = dict["y"] as? Double {
            // WKWebView는 isFlipped == true라 좌상단이 원점이고, JS의 clientX/clientY와 좌표계가 같음
            showImageDownloadMenu(in: webView, at: NSPoint(x: x, y: y))
        }
    }

    private func showImageDownloadMenu(in webView: WKWebView, at point: NSPoint) {
        NSApp.activate(ignoringOtherApps: true)

        let menu = NSMenu()
        let downloadItem = NSMenuItem(title: "이미지 다운로드", action: #selector(handleContextMenuDownload), keyEquivalent: "")
        downloadItem.target = self
        menu.addItem(downloadItem)

        menu.popUp(positioning: nil, at: point, in: webView)
    }

    @objc private func handleContextMenuDownload() {
        downloadCurrentImage()
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        decisionHandler(.allow, preferences)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        // 다운로드 가능한 응답인지 확인
        if !navigationResponse.canShowMIMEType {
            decisionHandler(.download)
        } else {
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }
    
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }
    
    // 이미지 다운로드 (프로그래밍 방식)
    func downloadCurrentImage() {
        guard let imageURLString = lastImageURL, let imageURL = URL(string: imageURLString) else {
            return
        }
        downloadImageFromURL(imageURL)
    }
    
    // ChatGPT 이미지 URL은 "/content"처럼 확장자 없는 API 엔드포인트인 경우가 많아
    // Content-Type을 보고 확장자를 붙여줘야 함 (없으면 macOS가 텍스트 편집기로 열려다 실패함)
    private static func suggestedFileName(for url: URL, mimeType: String?) -> String {
        let candidate = url.lastPathComponent
        if candidate.contains("."), !candidate.hasSuffix(".") {
            return candidate
        }

        let ext = mimeType.flatMap { UTType(mimeType: $0)?.preferredFilenameExtension } ?? "png"
        let base = candidate.isEmpty ? "image" : candidate
        return "\(base).\(ext)"
    }

    private func downloadImageFromURL(_ url: URL) {
        Task {
            do {
                var request = URLRequest(url: url)

                // WKWebView는 URLSession.shared와 쿠키를 공유하지 않으므로,
                // 로그인 세션이 필요한 이미지를 받으려면 웹뷰의 쿠키를 직접 실어 보내야 함
                if let webView = webView {
                    let cookies = await webView.configuration.websiteDataStore.httpCookieStore.allCookies()
                    request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
                }

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
                    return
                }

                await MainActor.run {
                    // 메뉴바 팝오버 상태에서는 앱이 key 상태가 아닐 수 있어
                    // NSSavePanel이 Powerbox로부터 sandbox extension을 못 받는 경우가 있음
                    NSApp.activate(ignoringOtherApps: true)

                    let savePanel = NSSavePanel()
                    savePanel.nameFieldStringValue = Self.suggestedFileName(for: url, mimeType: httpResponse.mimeType)
                    if let contentType = httpResponse.mimeType.flatMap({ UTType(mimeType: $0) }) {
                        savePanel.allowedContentTypes = [contentType]
                    }
                    savePanel.canCreateDirectories = true
                    savePanel.title = "이미지 저장"

                    savePanel.begin { result in
                        if result == .OK, let saveURL = savePanel.url {
                            try? data.write(to: saveURL)
                        }
                    }
                }
            } catch {}
        }
    }
    
    // 다운로드 목적지 지정 - 사용자에게 저장 위치 선택 다이얼로그 표시
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)

            let savePanel = NSSavePanel()
            savePanel.nameFieldStringValue = suggestedFilename
            savePanel.canCreateDirectories = true
            savePanel.title = "다운로드 저장 위치 선택"
            savePanel.message = "파일을 저장할 위치를 선택하세요"
            
            savePanel.begin { result in
                if result == .OK, let url = savePanel.url {
                    // Security-scoped bookmark 접근 시작
                    let didStartAccessing = url.startAccessingSecurityScopedResource()
                    defer {
                        if didStartAccessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                    
                    completionHandler(url)
                } else {
                    completionHandler(nil)
                }
            }
        }
    }
}

struct DownloadableWebView: NSViewRepresentable {
    let url: URL
    let coordinator: DownloadCoordinator
    
    func makeCoordinator() -> DownloadCoordinator {
        coordinator
    }
    
    func makeNSView(context: Context) -> WKWebView {
        // 화면 전환으로 이 뷰가 없어졌다가 다시 생겨도 세션(로그인, 스크롤 위치 등)이
        // 유지되도록, coordinator가 이미 들고 있는 WKWebView가 있으면 재사용함
        if let existingWebView = context.coordinator.webView {
            return existingWebView
        }

        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        context.coordinator.webView = webView
        
        // JavaScript로 이미지 감지 스크립트 추가
        let script = """
        document.addEventListener('contextmenu', function(e) {
            if (e.target.tagName === 'IMG') {
                e.preventDefault();
                window.webkit.messageHandlers.imageContext.postMessage({
                    type: 'contextmenu',
                    src: e.target.src,
                    x: e.clientX,
                    y: e.clientY
                });
            }
        }, true);

        document.addEventListener('click', function(e) {
            if (e.target.tagName === 'IMG') {
                window.webkit.messageHandlers.imageContext.postMessage({
                    type: 'click',
                    src: e.target.src
                });
            }
        }, true);
        """
        
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(userScript)
        webView.configuration.userContentController.add(context.coordinator, name: "imageContext")

        webView.load(URLRequest(url: url))

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // url은 이 화면에서 고정값이라 여기서 다시 로드할 필요가 없음.
        // coordinator의 @Published 값이 바뀔 때마다(예: 이미지 우클릭) 이 뷰가 다시 생성되는데,
        // 예전엔 여기서 webView.url != url을 비교해 리다이렉트된 URL과 달라졌다고 매번 재로드했었음.
    }
}

#Preview {
    ChatGPTWebView(currentScreen: .constant(.chatGPT), coordinator: DownloadCoordinator())
}
