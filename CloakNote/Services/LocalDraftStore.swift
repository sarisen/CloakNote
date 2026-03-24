import Foundation

final class LocalDraftStore {
    private let crypto = CryptoService()
    private let fileManager = FileManager.default

    func save(entry: JournalEntry, passphrase: String) async throws {
        let payload = try await crypto.encrypt(entry: entry, passphrase: passphrase)
        let data = try JSONEncoder.cloakNote.encode(payload)
        try fileManager.createDirectory(at: draftsDirectoryURL, withIntermediateDirectories: true)
        try data.write(to: url(for: entry.id), options: .atomic)
    }

    func loadAll(passphrase: String) async throws -> [JournalEntry] {
        guard fileManager.fileExists(atPath: draftsDirectoryURL.path) else { return [] }
        let urls = try fileManager.contentsOfDirectory(
            at: draftsDirectoryURL,
            includingPropertiesForKeys: nil
        )

        var entries: [JournalEntry] = []
        for url in urls where url.pathExtension == "json" {
            guard let data = try? Data(contentsOf: url),
                  let payload = try? JSONDecoder().decode(EncryptedPayload.self, from: data),
                  let entry = try? await crypto.decrypt(payload: payload, passphrase: passphrase) else {
                continue
            }
            entries.append(entry)
        }
        return entries.sorted { $0.modifiedAt > $1.modifiedAt }
    }

    func remove(id: UUID) throws {
        let fileURL = url(for: id)
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        try fileManager.removeItem(at: fileURL)
    }

    func removeIfMatching(_ entry: JournalEntry, passphrase: String) async throws {
        let fileURL = url(for: entry.id)
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let payload = try? JSONDecoder().decode(EncryptedPayload.self, from: data),
              let current = try? await crypto.decrypt(payload: payload, passphrase: passphrase) else {
            return
        }

        guard current.modifiedAt <= entry.modifiedAt else { return }
        try fileManager.removeItem(at: fileURL)
    }

    private func url(for id: UUID) -> URL {
        draftsDirectoryURL.appendingPathComponent("\(id.uuidString.lowercased()).json", isDirectory: false)
    }

    private var draftsDirectoryURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport
            .appendingPathComponent(Constants.appName, isDirectory: true)
            .appendingPathComponent("drafts", isDirectory: true)
    }
}
