import AppKit
import Sparkle

// 자동 업데이트(다운로드/설치)가 실패했을 때(예: 서명 문제로 Gatekeeper가 막는 경우)
// 설치 파일을 다운로드 폴더로 바로 받아주고 Finder에서 보여줌 (브라우저 안 거침)
class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
    private var pendingDownloadURL: URL?

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        pendingDownloadURL = item.fileURL
    }

    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        let nsError = error as NSError

        // 1001: 업데이트 없음(정상), 4007: 사용자가 직접 취소함 — 둘 다 실패 안내 불필요
        guard nsError.code != 1001, nsError.code != 4007 else { return }
        guard let downloadURL = pendingDownloadURL else { return }

        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "자동 업데이트에 실패했습니다"
            alert.informativeText = "설치 파일을 다운로드 폴더로 받은 후 직접 열어서 설치해 주세요."
            alert.addButton(withTitle: "설치파일 다운로드")
            alert.addButton(withTitle: "취소")

            if alert.runModal() == .alertFirstButtonReturn {
                self.downloadInstaller(from: downloadURL)
            }
        }
    }

    private func downloadInstaller(from url: URL) {
        guard let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            return
        }
        let destination = downloadsDir.appendingPathComponent(url.lastPathComponent)

        let task = URLSession.shared.downloadTask(with: url) { tempURL, _, _ in
            guard let tempURL = tempURL else { return }
            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.moveItem(at: tempURL, to: destination)
                DispatchQueue.main.async {
                    NSWorkspace.shared.activateFileViewerSelecting([destination])
                }
            } catch {
                // 다운로드 저장 실패해도 조용히 무시 — 사용자가 업데이트 확인을 다시 시도할 수 있음
            }
        }
        task.resume()
    }
}
