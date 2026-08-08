//
//  NetworkServie.swift
//  bulgul_front
//
//  Created by 안상영 on 7/28/26.
//
import Foundation

extension Notification.Name {
    // 토큰 만료(401)로 재로그인이 필요할 때 앱 전역에 알림
    static let authTokenExpired = Notification.Name("authTokenExpired")
}

// FastAPI가 HTTPException에 담아 보내는 {"detail": "..."} 메시지를 그대로 노출하기 위한 에러
struct APIError: LocalizedError {
    let statusCode: Int
    let detail: String?

    var errorDescription: String? { detail }
}

private struct APIErrorBody: Decodable {
    let detail: String?
}

class NetworkClient {
    static let shared = NetworkClient()
    private init() {}

    // Keychain에서 토큰 가져오기
    private var token: String? {
        KeychainTokenStore().load()
    }

    // 어떤 데이터 타입이든(Generics <T>) 받아서 처리하는 공통 함수
    func request<T: Decodable>(
        path: String,
        method: String,
        body: Encodable? = nil
    ) async throws -> T {
        let data = try await performRequest(path: path, method: method, body: body)
        return try JSONDecoder().decode(T.self, from: data)
    }

    // 응답 본문을 신경 쓰지 않는 요청(예: 저장/삭제)용
    @discardableResult
    func requestWithoutDecoding(
        path: String,
        method: String,
        body: Encodable? = nil
    ) async throws -> Data {
        try await performRequest(path: path, method: method, body: body)
    }

    private func performRequest(
        path: String,
        method: String,
        body: Encodable?
    ) async throws -> Data {
        // 1. URL 생성
        guard let url = URL(string: "https://bulguldesign.com" + path) else {
            throw URLError(.badURL)
        }

        // 2. HTTP Request 설정 (Header, Body)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 토큰이 있으면 Authorization 헤더 추가
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        // 3. 실제 인터넷 통신 실행
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        // 4. 토큰 만료/무효화 공통 처리: 저장된 토큰을 지우고 재로그인 화면으로 보냄
        if httpResponse.statusCode == 401 {
            KeychainTokenStore().delete()
            NotificationCenter.default.post(name: .authTokenExpired, object: nil)
            throw URLError(.userAuthenticationRequired)
        }

        // 5. HTTP 상태 코드 검증 (200번대인지 확인)
        guard (200...299).contains(httpResponse.statusCode) else {
            let detail = try? JSONDecoder().decode(APIErrorBody.self, from: data).detail
            throw APIError(statusCode: httpResponse.statusCode, detail: detail)
        }

        return data
    }
}
