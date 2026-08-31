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

    func uploadFile(fileURL: URL, onProgress: ((Double) -> Void)? = nil) async throws {
        try await NetworkClient.shared.uploadFile(path: "/api/api_v1/files", fileURL: fileURL, onProgress: onProgress)
    }

    func downloadFile(filename: String) async throws -> Data {
        try await NetworkClient.shared.requestWithoutDecoding(path: "/api/api_v1/files/\(filename)", method: "GET")
    }

    func getThumbnail(filename: String) async throws -> Data {
        try await NetworkClient.shared.requestWithoutDecoding(path: "/api/api_v1/files/\(filename)/thumbnail", method: "GET")
    }

    func deleteFile(filename: String) async throws {
        try await NetworkClient.shared.requestWithoutDecoding(path: "/api/api_v1/files/\(filename)", method: "DELETE")
    }

    func getStorageUsage() async throws -> StorageUsage {
        try await NetworkClient.shared.request(path: "/api/api_v1/files/storage", method: "GET")
    }

    func getMemo(filename: String) async throws -> String {
        let response: FileMemoResponse = try await NetworkClient.shared.request(path: "/api/api_v1/files/\(filename)/memo", method: "GET")
        return response.memo
    }

    func saveMemo(filename: String, memo: String) async throws {
        try await NetworkClient.shared.requestWithoutDecoding(
            path: "/api/api_v1/files/\(filename)/memo",
            method: "PUT",
            body: FileMemoRequest(memo: memo)
        )
    }
}

private struct FileMemoResponse: Decodable {
    let memo: String
}

private struct FileMemoRequest: Encodable {
    let memo: String
}

struct StorageUsage: Decodable {
    let used: Int64
    let limit: Int64?
}
