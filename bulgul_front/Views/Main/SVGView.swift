import SwiftUI
import WebKit

// 스크롤 이벤트를 부모로 전달하는 커스텀 WebView
class NonScrollableWebView: WKWebView {
    override func scrollWheel(with event: NSEvent) {
        // 스크롤 이벤트를 부모 뷰로 전달
        self.nextResponder?.scrollWheel(with: event)
    }
}

struct SVGView: NSViewRepresentable {
    let svgCode: String
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = NonScrollableWebView()
        webView.setValue(false, forKey: "drawsBackground")
        
        // 스크롤 비활성화
        webView.enclosingScrollView?.hasVerticalScroller = false
        webView.enclosingScrollView?.hasHorizontalScroller = false
        webView.enclosingScrollView?.verticalScrollElasticity = .none
        webView.enclosingScrollView?.horizontalScrollElasticity = .none
        
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <style>
                body {
                    margin: 0;
                    padding: 0;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    min-height: 100vh;
                    background: transparent;
                    overflow: hidden;
                }
                svg {
                    max-width: 100%;
                    max-height: 100%;
                    height: auto;
                    pointer-events: none;
                }
            </style>
        </head>
        <body>
            \(svgCode)
        </body>
        </html>
        """
        
        webView.loadHTMLString(html, baseURL: nil)
        
        // 스크롤 비활성화 (로드 후에도 적용)
        webView.enclosingScrollView?.hasVerticalScroller = false
        webView.enclosingScrollView?.hasHorizontalScroller = false
    }
}
