//
//  AuthService.swift
//  bulgul_front
//
//  Created by 안상영 on 7/30/26.
//
class AuthService {
    static let shared = AuthService() // AuthService만의 싱글톤
    private init() {}
    
    func login(email: String, password: String) async throws -> LoginResponse {
        // NetworkClient.shared에 요청을 위임

        return try await NetworkClient.shared.request(
            path: "/api/api_v1/auth/login",
            method: "POST",
            body: LoginRequest(email: email, password: password)
        )
    }

    func register(email: String, password: String) async throws -> LoginResponse {
        // 회원가입 성공 시 서버가 로그인과 동일한 형태로 토큰을 바로 내려줌
        return try await NetworkClient.shared.request(
            path: "/api/api_v1/auth/register",
            method: "POST",
            body: RegisterRequest(email: email, password: password)
        )
    }
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RegisterRequest: Encodable {
    let email: String
    let password: String
}

struct User: Decodable {
    let id: Int
    let email: String
    let isAdmin: Bool
}

// 백엔드에서 받아올 응답 구조체 (Decodable 필수)
struct LoginResponse: Decodable {
    let success : Bool?
    let token: String?
    let user : User?
}
