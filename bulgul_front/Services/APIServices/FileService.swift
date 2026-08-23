import Foundation

struct FileInfo: Decodable, Identifiable {
    var id: String { filename }
    let filename: String
    let size: Int
    let modifiedAt: Double

    enum CodingKeys: String, CodingKey {
        case filename, size
        case modifiedAt = "modified_at"
    }
}

class FileService {
    static let shared = FileService()
    private init() {}

    func listFiles() async throws -> [FileInfo] {
        try await NetworkClient.shared.request(path: "/api/api_v1/files", method: "GET")
    }

    func uploadFile(fileURL: URL) async throws {
        try await NetworkClient.shared.uploadFile(path: "/api/api_v1/files", fileURL: fileURL)
    }

    func downloadFile(filename: String) async throws -> Data {
        try await NetworkClient.shared.requestWithoutDecoding(path: "/api/api_v1/files/\(filename)", method: "GET")
    }

    func deleteFile(filename: String) async throws {
        try await NetworkClient.shared.requestWithoutDecoding(path: "/api/api_v1/files/\(filename)", method: "DELETE")
    }
}
