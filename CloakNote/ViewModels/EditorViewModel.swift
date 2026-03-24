import Foundation

@Observable
final class EditorViewModel {
    var entry: JournalEntry
    var isDirty = false
    var showDatePicker = false
    var newTag = ""

    private var saveTask: Task<Void, Never>?

    init(entry: JournalEntry) {
        self.entry = entry
    }

    var wordCount: Int {
        entry.content.split(separator: " ").count
    }

    func updateTitle(_ title: String) {
        entry.title = title
        entry.modifiedAt = Date()
        isDirty = true
    }

    func updateContent(_ content: String) {
        entry.content = content
        entry.modifiedAt = Date()
        isDirty = true
    }

    func updateMood(_ mood: Mood) {
        entry.mood = mood
        entry.modifiedAt = Date()
        isDirty = true
    }

    func updateDate(_ date: Date) {
        entry.date = date
        entry.modifiedAt = Date()
        isDirty = true
    }

    func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespaces).lowercased()
        guard !tag.isEmpty, !entry.tags.contains(tag) else { return }
        entry.tags.append(tag)
        newTag = ""
        isDirty = true
    }

    func removeTag(_ tag: String) {
        entry.tags.removeAll { $0 == tag }
        isDirty = true
    }

    func scheduleAutoSave(appState: AppState) {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled, self.isDirty else { return }
            await appState.saveEntry(self.entry)
            self.isDirty = false
        }
    }

    /// Navigation'da veya kapanmada bekleyen değişiklikleri hemen kaydet
    func saveIfDirty(appState: AppState) {
        guard isDirty else { return }
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            guard let self else { return }
            await appState.saveEntry(self.entry)
            self.isDirty = false
        }
    }
}
