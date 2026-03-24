import Foundation

final class SyncService {
    let crypto = CryptoService()
    let github = GitHubService()
    let localDrafts = LocalDraftStore()

    struct GitHubConfig {
        let token: String
        let owner: String
        let repo: String
    }

    private struct StoredGitHubConfig: Codable {
        let token: EncryptedSecret
        let owner: String
        let repo: String
    }

    func hasGitHubConfig() -> Bool {
        FileManager.default.fileExists(atPath: configURL.path)
    }

    func loadGitHubConfig(passphrase: String) async -> Bool {
        guard let config = await readGitHubConfig(passphrase: passphrase) else {
            return false
        }
        github.configure(token: config.token, owner: config.owner, repo: config.repo)
        return true
    }

    func saveGitHubConfig(token: String, owner: String, repo: String, passphrase: String) async throws {
        let config = GitHubConfig(token: token, owner: owner, repo: repo)
        try await persistGitHubConfig(config, passphrase: passphrase)
        github.configure(token: token, owner: owner, repo: repo)
    }

    func currentGitHubConfig(passphrase: String) async -> GitHubConfig? {
        await readGitHubConfig(passphrase: passphrase)
    }

    func loadLocalDrafts(passphrase: String) async -> [JournalEntry] {
        (try? await localDrafts.loadAll(passphrase: passphrase)) ?? []
    }

    func saveLocalDraft(_ entry: JournalEntry, passphrase: String) async throws {
        try await localDrafts.save(entry: entry, passphrase: passphrase)
    }

    func removeLocalDraftIfSynced(_ entry: JournalEntry, passphrase: String) async {
        try? await localDrafts.removeIfMatching(entry, passphrase: passphrase)
    }

    func removeLocalDraft(_ entry: JournalEntry) {
        try? localDrafts.remove(id: entry.id)
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
            } catch { }
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

        // Repo-level writes can race on GitHub's Contents API, so always retry with
        // the latest remote SHA before surfacing an error.
        for attempt in 0..<10 {
            let existingSha = try? await github.fetchEntry(filename: filename).sha
            do {
                try await github.pushEntry(filename: filename, content: jsonString, sha: existingSha, message: message)
                return
            } catch GitHubService.GitHubError.apiError(let status, _) where status == 409 || status == 422 {
                if attempt == 9 {
                    if let latestSha = try? await github.fetchEntry(filename: filename).sha {
                        try? await github.deleteEntry(
                            filename: filename,
                            sha: latestSha,
                            message: "\(languageManager.saveCommitPrefix): \(dateStr) - \(title) [reset]"
                        )
                    }

                    try await github.pushEntry(
                        filename: filename,
                        content: jsonString,
                        sha: nil,
                        message: message
                    )
                    return
                }
                try? await Task.sleep(for: .milliseconds(250))
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

    private func readGitHubConfig(passphrase: String) async -> GitHubConfig? {
        guard let data = try? Data(contentsOf: configURL),
              let stored = try? JSONDecoder().decode(StoredGitHubConfig.self, from: data),
              let token = try? await crypto.decryptSecret(stored.token, passphrase: passphrase) else {
            return nil
        }
        return GitHubConfig(token: token, owner: stored.owner, repo: stored.repo)
    }

    private func persistGitHubConfig(_ config: GitHubConfig, passphrase: String) async throws {
        let directory = configURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encryptedToken = try await crypto.encryptSecret(config.token, passphrase: passphrase)
        let stored = StoredGitHubConfig(token: encryptedToken, owner: config.owner, repo: config.repo)
        let data = try JSONEncoder().encode(stored)
        try data.write(to: configURL, options: .atomic)
    }

    private var configURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport
            .appendingPathComponent(Constants.appName, isDirectory: true)
            .appendingPathComponent("github-config.json", isDirectory: false)
    }
}
