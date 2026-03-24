import Foundation
import SwiftUI
import AppKit

actor EntrySaveCoordinator {
    private var latestByID: [UUID: JournalEntry] = [:]
    private var activeIDs: Set<UUID> = []

    func startIfNeeded(with entry: JournalEntry) -> JournalEntry? {
        latestByID[entry.id] = entry
        guard !activeIDs.contains(entry.id) else { return nil }
        activeIDs.insert(entry.id)
        return latestByID.removeValue(forKey: entry.id)
    }

    func nextOrFinish(for id: UUID) -> JournalEntry? {
        if let next = latestByID.removeValue(forKey: id) {
            return next
        }
        activeIDs.remove(id)
        return nil
    }
}

@Observable
final class AppState {
    var isLocked = true
    var isFirstLaunch = false
    var passphrase: String = ""

    var entries: [JournalEntry] = []
    var selectedEntryId: UUID? = nil
    var isLoading = false
    var errorMessage: String? = nil
    var syncStatus: SyncStatus = .idle
    var decryptionFailed = false

    // Tema
    var colorScheme: ColorScheme? = nil

    // Auto-lock
    var autoLockInterval: TimeInterval = 1800
    private var autoLockTask: Task<Void, Never>?
    private var lastActivityDate = Date()
    private let saveCoordinator = EntrySaveCoordinator()

    let syncService = SyncService()

    init() {
        // Bilgisayar uyku/ekran kilidi → otomatik kilitle
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            self?.lock()
        }
        nc.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: .main) { [weak self] _ in
            self?.lock()
        }
        nc.addObserver(forName: NSWorkspace.sessionDidResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.lock()
        }
    }

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case synced
        case error(String)
    }

    var selectedEntry: JournalEntry? {
        entries.first { $0.id == selectedEntryId }
    }

    var entriesByMonth: [(String, [JournalEntry])] {
        let languageManager = LanguageManager()
        let grouped = Dictionary(grouping: entries) { entry in
            languageManager.monthYearString(for: entry.date)
        }
        return grouped.sorted { pair1, pair2 in
            guard let d1 = pair1.value.first?.date, let d2 = pair2.value.first?.date else { return false }
            return d1 > d2
        }
    }

    func unlock(passphrase: String) async {
        self.passphrase = passphrase
        self.isLoading = true
        self.errorMessage = nil
        do {
            entries = try await syncService.fetchAllEntries(passphrase: passphrase)
            isLocked = false
            lastActivityDate = Date()
            startAutoLockTimer()
        } catch is CryptoService.CryptoError {
            self.decryptionFailed = true
            self.passphrase = ""
        } catch {
            self.errorMessage = LanguageManager().genericError(error.localizedDescription)
            self.passphrase = ""
        }
        self.isLoading = false
    }

    func lock() {
        autoLockTask?.cancel()
        isLocked = true
        passphrase = ""
        entries = []
        selectedEntryId = nil
    }

    func recordActivity() {
        lastActivityDate = Date()
    }

    private func startAutoLockTimer() {
        autoLockTask?.cancel()
        guard autoLockInterval > 0 else { return }
        autoLockTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard !Task.isCancelled else { return }
                if !isLocked && Date().timeIntervalSince(lastActivityDate) >= autoLockInterval {
                    lock()
                    return
                }
            }
        }
    }

    func createNewEntry() -> JournalEntry {
        let entry = JournalEntry()
        entries.insert(entry, at: 0)
        selectedEntryId = entry.id
        return entry
    }

    func saveEntry(_ entry: JournalEntry) async {
        guard !passphrase.isEmpty else { return }
        if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[idx] = entry
        }

        var pendingEntry = await saveCoordinator.startIfNeeded(with: entry)

        while let entryToSave = pendingEntry {
            syncStatus = .syncing
            do {
                try await syncService.saveEntry(entryToSave, passphrase: passphrase)
                syncStatus = .synced
            } catch {
                syncStatus = .error(error.localizedDescription)
            }
            pendingEntry = await saveCoordinator.nextOrFinish(for: entry.id)
        }
    }

    func deleteEntry(_ entry: JournalEntry) async {
        entries.removeAll { $0.id == entry.id }
        if selectedEntryId == entry.id {
            selectedEntryId = entries.first?.id
        }
        do {
            try await syncService.deleteEntry(entry)
        } catch {
            errorMessage = LanguageManager().deleteError(error.localizedDescription)
        }
    }

    func checkFirstLaunch() {
        isFirstLaunch = !syncService.loadGitHubConfig()
    }

}
