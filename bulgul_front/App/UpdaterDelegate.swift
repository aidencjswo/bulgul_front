import AppKit
import Sparkle

// 자동 업데이트(다운로드/설치)가 실패했을 때(예: 서명 문제로 Gatekeeper가 막는 경우)
// 사용자가 수동으로 받을 수 있도록 다운로드 페이지 링크를 안내
class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        let nsError = error as NSError

        // 1001: 업데이트 없음(정상), 4007: 사용자가 직접 취소함 — 둘 다 실패 안내 불필요
        guard nsError.code != 1001, nsError.code != 4007 else { return }

        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "자동 업데이트에 실패했습니다"
            alert.informativeText = "아래 페이지에서 최신 버전을 직접 다운로드해서 설치해 주세요."
            alert.addButton(withTitle: "다운로드 페이지 열기")
            alert.addButton(withTitle: "닫기")

            if alert.runModal() == .alertFirstButtonReturn,
               let url = URL(string: "https://github.com/aidencjswo/bulgul_front/releases/latest") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
