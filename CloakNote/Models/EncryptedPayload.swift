import Foundation

struct EncryptedPayload: Codable {
    let version: Int
    let salt: String
    let iv: String
    let data: String
    let createdAt: String
    let modifiedAt: String
}
