import Foundation
import SwiftUI
import AppKit

actor SaveCoordinator {
    private var latestByID: [UUID: JournalEntry] = [:]
    private var orderedIDs: [UUID] = []
    private var isProcessing = false

    func enqueue(_ entry: JournalEntry) -> JournalEntry? {
        latestByID[entry.id] = entry
        if !orderedIDs.contains(entry.id) {
            orderedIDs.append(entry.id)
        }
        guard !isProcessing else { return nil }
        isProcessing = true
        return dequeueNext()
    }

    func next() -> JournalEntry? {
        if let next = dequeueNext() {
            return next
        }
        isProcessing = false
        return nil
    }

    private func dequeueNext() -> JournalEntry? {
        while let id = orderedIDs.first {
            orderedIDs.removeFirst()
            if let entry = latestByID.removeValue(forKey: id) {
                return entry
            }
        }
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
    private var draftSyncTask: Task<Void, Never>?
    private var lastActivityDate = Date()
    private let saveCoordinator = SaveCoordinator()

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
        let localEntries = await syncService.loadLocalDrafts(passphrase: passphrase)
        do {
            let remoteEntries = try await syncService.fetchAllEntries(passphrase: passphrase)
            entries = mergeEntries(remoteEntries, with: localEntries)
            isLocked = false
            lastActivityDate = Date()
            startAutoLockTimer()
            startDraftSyncTimer()
            await flushPendingDrafts()
        } catch is CryptoService.CryptoError {
            self.decryptionFailed = true
            self.passphrase = ""
        } catch {
            if !localEntries.isEmpty {
                entries = localEntries
                isLocked = false
                lastActivityDate = Date()
                syncStatus = .error(error.localizedDescription)
                startAutoLockTimer()
                startDraftSyncTimer()
            } else {
                self.errorMessage = LanguageManager().genericError(error.localizedDescription)
                self.passphrase = ""
            }
        }
        self.isLoading = false
    }

    func lock() {
        autoLockTask?.cancel()
        draftSyncTask?.cancel()
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

    private func startDraftSyncTimer() {
        draftSyncTask?.cancel()
        draftSyncTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard !Task.isCancelled, !isLocked, !passphrase.isEmpty else { return }
                await flushPendingDrafts()
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

        do {
            try await syncService.saveLocalDraft(entry, passphrase: passphrase)
        } catch {
            syncStatus = .error(error.localizedDescription)
            return
        }

        var pendingEntry = await saveCoordinator.enqueue(entry)

        while let entryToSave = pendingEntry {
            syncStatus = .syncing
            do {
                try await syncService.saveEntry(entryToSave, passphrase: passphrase)
                await syncService.removeLocalDraftIfSynced(entryToSave, passphrase: passphrase)
                syncStatus = .synced
            } catch {
                syncStatus = .error(error.localizedDescription)
            }
            pendingEntry = await saveCoordinator.next()
        }
    }

    func deleteEntry(_ entry: JournalEntry) async {
        entries.removeAll { $0.id == entry.id }
        if selectedEntryId == entry.id {
            selectedEntryId = entries.first?.id
        }
        syncService.removeLocalDraft(entry)
        do {
            try await syncService.deleteEntry(entry)
        } catch {
            errorMessage = LanguageManager().deleteError(error.localizedDescription)
        }
    }

    func checkFirstLaunch() {
        isFirstLaunch = !syncService.loadGitHubConfig()
    }

    private func mergeEntries(_ remoteEntries: [JournalEntry], with localEntries: [JournalEntry]) -> [JournalEntry] {
        var merged = Dictionary(uniqueKeysWithValues: remoteEntries.map { ($0.id, $0) })

        for local in localEntries {
            if let remote = merged[local.id] {
                merged[local.id] = local.modifiedAt >= remote.modifiedAt ? local : remote
            } else {
                merged[local.id] = local
            }
        }

        return merged.values.sorted { $0.date > $1.date }
    }

    private func flushPendingDrafts() async {
        guard !passphrase.isEmpty else { return }
        let drafts = await syncService.loadLocalDrafts(passphrase: passphrase)
        for draft in drafts {
            await saveEntry(draft)
        }
    }
}
