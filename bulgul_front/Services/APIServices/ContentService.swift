//
//  ContentService.swift
//  bulgul_front
//
//  Created by 안상영 on 8/2/26.
//

class ContentService {
    
    static let shared = ContentService() // AuthService만의 싱글톤
    
    private init() {}
    
    func getTips() async throws -> [TipsResponse] {
        // NetworkClient.shared에 요청을 위임

        return try await NetworkClient.shared.request(
            path: "/api/api_v1/design/tips",
            method: "GET"
        )
    }

    func deleteTip(id: Int) async throws {
        try await NetworkClient.shared.requestWithoutDecoding(
            path: "/api/api_v1/design/tips/\(id)",
            method: "DELETE"
        )
    }
}

struct TipsResponse : Decodable{
    let id: Int?
    let title: String?
    let category: String?
    let subcategory: String?
    let shortcuts: [String?]
    let description: String?
    let tags: [String?]
    let isFavorite: Bool?
    let createdAt: String?
    let steps: [String?]
    let svgs: [String?]
    let pngs: [String?]
    
}
