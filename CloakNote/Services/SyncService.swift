import Foundation

final class SyncService {
    let crypto = CryptoService()
    let github = GitHubService()
    let keychain = KeychainService()

    static let tokenKey = "github_token"
    static let ownerKey = "github_owner"
    static let repoKey = "github_repo"

    func loadGitHubConfig() -> Bool {
        guard let token = keychain.retrieve(key: Self.tokenKey),
              let owner = keychain.retrieve(key: Self.ownerKey),
              let repo = keychain.retrieve(key: Self.repoKey) else {
            return false
        }
        github.configure(token: token, owner: owner, repo: repo)
        return true
    }

    func saveGitHubConfig(token: String, owner: String, repo: String) throws {
        try keychain.save(key: Self.tokenKey, value: token)
        try keychain.save(key: Self.ownerKey, value: owner)
        try keychain.save(key: Self.repoKey, value: repo)
        github.configure(token: token, owner: owner, repo: repo)
    }

    func fetchAllEntries(passphrase: String) async throws -> [JournalEntry] {
        let files = try await github.listEntries()
        var entries: [JournalEntry] = []
        for file in files where file.name.hasSuffix(".enc.json") {
            do {
                let (content, _) = try await github.fetchEntry(filename: file.name)
                let payload = try JSONDecoder().decode(EncryptedPayload.self, from: Data(content.utf8))
                let entry = try await crypto.decrypt(payload: payload, passphrase: passphrase)
                entries.append(entry)
            } catch {
                // Bozuk veya farklı passphrase ile şifrelenmiş dosyayı atla
                print("Skipping \(file.name): \(error)")
            }
        }
        let encFiles = files.filter { $0.name.hasSuffix(".enc.json") }
        // Dosya var ama hiçbiri açılamadıysa → büyük ihtimal yanlış passphrase
        if !encFiles.isEmpty && entries.isEmpty {
            throw CryptoService.CryptoError.decryptionFailed
        }
        return entries.sorted { $0.date > $1.date }
    }

    func saveEntry(_ entry: JournalEntry, passphrase: String) async throws {
        let languageManager = LanguageManager()
        let payload = try await crypto.encrypt(entry: entry, passphrase: passphrase)
        let jsonData = try JSONEncoder.cloakNote.encode(payload)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        let filename = Self.filename(for: entry.date, id: entry.id)
        let dateStr = Self.dateFormatter.string(from: entry.date)
        let title = entry.title.isEmpty ? languageManager.untitled : String(entry.title.prefix(50))
        let message = "\(languageManager.saveCommitPrefix): \(dateStr) - \(title)"

        // 409 conflict olursa fresh SHA çekip tekrar dene (max 3 deneme)
        for attempt in 0..<3 {
            let existingSha = try? await github.fetchEntry(filename: filename).sha
            do {
                try await github.pushEntry(filename: filename, content: jsonString, sha: existingSha, message: message)
                return
            } catch GitHubService.GitHubError.apiError(let status, _) where status == 409 || status == 422 {
                if attempt == 2 {
                    throw GitHubService.GitHubError.apiError(
                        statusCode: status,
                        message: languageManager.unresolvedConflictError(attempts: attempt + 1)
                    )
                }
                try? await Task.sleep(for: .milliseconds(300))
            }
        }
    }

    func deleteEntry(_ entry: JournalEntry) async throws {
        let filename = Self.filename(for: entry.date, id: entry.id)
        let (_, sha) = try await github.fetchEntry(filename: filename)
        try await github.deleteEntry(filename: filename, sha: sha)
    }

    static func filename(for date: Date, id: UUID) -> String {
        let dateStr = dateFormatter.string(from: date)
        let shortId = String(id.uuidString.prefix(8)).lowercased()
        return "\(dateStr)_\(shortId).enc.json"
    }

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
