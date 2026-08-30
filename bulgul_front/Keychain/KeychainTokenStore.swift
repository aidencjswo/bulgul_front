//
//  KeychainTokenStore.swift
//  bulgul_front
//
//  Created by 안상영 on 8/3/26.
//

import Security
import Foundation

struct KeychainTokenStore {
    private let account = "com.yourapp.refreshToken"
    
    func save(_ token: String) {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]

        // 기존 항목이 있으면 갱신, 없으면 새로 추가 — 삭제 후 재추가 방식은
        // SecItemAdd가 errSecDuplicateItem으로 조용히 실패할 경우 새 토큰이
        // 저장되지 않고 예전 토큰이 계속 남는 문제가 있어 update-then-add로 변경.
        let updateStatus = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)

        if updateStatus == errSecItemNotFound {
            let attributes: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: account,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
            ]
            let addStatus = SecItemAdd(attributes as CFDictionary, nil)
            if addStatus != errSecSuccess {
                print("[KEYCHAIN] save failed: SecItemAdd status=\(addStatus)")
            }
        } else if updateStatus != errSecSuccess {
            print("[KEYCHAIN] save failed: SecItemUpdate status=\(updateStatus)")
        }
    }
    
    func load() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        return token
    }
    
    func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
