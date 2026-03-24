import Foundation
import CryptoKit
import CommonCrypto

final class CryptoService {

    nonisolated private func deriveKey(from passphrase: String, salt: Data) throws -> SymmetricKey {
        let keyLength = 32
        let pbkdf2Iterations = 600_000
        let passphraseData = Data(passphrase.utf8)
        var derivedKey = Data(count: keyLength)
        let result = derivedKey.withUnsafeMutableBytes { derivedKeyBytes in
            salt.withUnsafeBytes { saltBytes in
                passphraseData.withUnsafeBytes { passwordBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                        passphraseData.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(pbkdf2Iterations),
                        derivedKeyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        keyLength
                    )
                }
            }
        }
        guard result == kCCSuccess else { throw CryptoError.keyDerivationFailed }
        return SymmetricKey(data: derivedKey)
    }

    /// PBKDF2'yi background thread'de çalıştır (600K iterasyon main thread'i dondurur)
    nonisolated func deriveKeyAsync(from passphrase: String, salt: Data) async throws -> SymmetricKey {
        try await Task.detached(priority: .userInitiated) {
            try self.deriveKey(from: passphrase, salt: salt)
        }.value
    }

    func generateSalt() -> Data {
        let saltLength = 32
        var salt = Data(count: saltLength)
        _ = salt.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, saltLength, $0.baseAddress!)
        }
        return salt
    }

    func encrypt(entry: JournalEntry, passphrase: String) async throws -> EncryptedPayload {
        let salt = generateSalt()
        let key = try await deriveKeyAsync(from: passphrase, salt: salt)
        let jsonData = try JSONEncoder().encode(entry)
        let sealedBox = try AES.GCM.seal(jsonData, using: key)
        let combined = sealedBox.combined!
        let formatter = ISO8601DateFormatter()
        return EncryptedPayload(
            version: 1,
            salt: salt.base64EncodedString(),
            iv: Data(sealedBox.nonce).base64EncodedString(),
            data: combined.base64EncodedString(),
            createdAt: formatter.string(from: entry.createdAt),
            modifiedAt: formatter.string(from: entry.modifiedAt)
        )
    }

    func decrypt(payload: EncryptedPayload, passphrase: String) async throws -> JournalEntry {
        guard let salt = Data(base64Encoded: payload.salt),
              let combined = Data(base64Encoded: payload.data) else {
            throw CryptoError.invalidPayload
        }
        let key = try await deriveKeyAsync(from: passphrase, salt: salt)
        let sealedBox = try AES.GCM.SealedBox(combined: combined)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        return try JSONDecoder().decode(JournalEntry.self, from: decryptedData)
    }

    func encryptSecret(_ secret: String, passphrase: String) async throws -> EncryptedSecret {
        let salt = generateSalt()
        let key = try await deriveKeyAsync(from: passphrase, salt: salt)
        let secretData = Data(secret.utf8)
        let sealedBox = try AES.GCM.seal(secretData, using: key)
        return EncryptedSecret(
            salt: salt.base64EncodedString(),
            data: sealedBox.combined!.base64EncodedString()
        )
    }

    func decryptSecret(_ secret: EncryptedSecret, passphrase: String) async throws -> String {
        guard let salt = Data(base64Encoded: secret.salt),
              let combined = Data(base64Encoded: secret.data) else {
            throw CryptoError.invalidPayload
        }
        let key = try await deriveKeyAsync(from: passphrase, salt: salt)
        let sealedBox = try AES.GCM.SealedBox(combined: combined)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        guard let value = String(data: decryptedData, encoding: .utf8) else {
            throw CryptoError.invalidPayload
        }
        return value
    }

    enum CryptoError: LocalizedError {
        case invalidPayload
        case decryptionFailed
        case keyDerivationFailed

        var errorDescription: String? {
            let languageManager = LanguageManager()
            switch self {
            case .invalidPayload: return languageManager.invalidEncryptedPayload
            case .decryptionFailed: return languageManager.decryptionFailedMessage
            case .keyDerivationFailed: return languageManager.keyDerivationFailed
            }
        }
    }
}

struct EncryptedSecret: Codable {
    let salt: String
    let data: String
}
