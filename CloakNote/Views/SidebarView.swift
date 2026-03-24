import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) var appState
    @Environment(LanguageManager.self) var languageManager
    @State private var searchText = ""
    @State private var selectedTag: String? = nil
    @State private var entryToDelete: JournalEntry? = nil
    @State private var showDeleteAlert = false

    var allTags: [String] {
        let tags = appState.entries.flatMap { $0.tags }
        let unique = Array(Set(tags)).sorted()
        return unique
    }

    var filteredEntriesByMonth: [(String, [JournalEntry])] {
        var base = appState.entries

        if let tag = selectedTag {
            base = base.filter { $0.tags.contains(tag) }
        }

        if !searchText.isEmpty {
            let lower = searchText.lowercased()
            base = base.filter {
                $0.title.lowercased().contains(lower) || $0.content.lowercased().contains(lower)
            }
        }

        if base.isEmpty { return [] }

        let grouped = Dictionary(grouping: base) { entry in
            languageManager.monthYearString(for: entry.date)
        }
        return grouped.sorted { pair1, pair2 in
            guard let d1 = pair1.value.first?.date, let d2 = pair2.value.first?.date else { return false }
            return d1 > d2
        }
    }

    var body: some View {
        @Bindable var appState = appState
        VStack(spacing: 0) {
            List(selection: $appState.selectedEntryId) {
                // Tag filtresi
                if !allTags.isEmpty {
                    Section(languageManager.tags) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(allTags, id: \.self) { tag in
                                    Button {
                                        selectedTag = selectedTag == tag ? nil : tag
                                    } label: {
                                        Text("#\(tag)")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(selectedTag == tag ? Color.accentColor : Color.secondary.opacity(0.15))
                                            .foregroundStyle(selectedTag == tag ? Color.white : Color.primary)
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                ForEach(filteredEntriesByMonth, id: \.0) { month, entries in
                    Section(month) {
                        ForEach(entries) { entry in
                            EntryRowView(entry: entry)
                                .tag(entry.id)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        entryToDelete = entry
                                        showDeleteAlert = true
                                    } label: {
                                        Label(languageManager.delete, systemImage: "trash")
                                    }
                                }
                        }
                        .onDelete { offsets in
                            for idx in offsets {
                                let entry = entries[idx]
                                Task { await appState.deleteEntry(entry) }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: languageManager.search)

            Divider()
            HStack {
                Button {
                    _ = appState.createNewEntry()
                } label: {
                    Label(languageManager.newNote, systemImage: "plus")
                        .font(.callout)
                }
                .keyboardShortcut("n", modifiers: .command)

                Spacer()

                Button {
                    appState.lock()
                } label: {
                    Label(languageManager.lock, systemImage: "lock.fill")
                        .font(.callout)
                }
                .keyboardShortcut("l", modifiers: .command)
            }
            .padding(10)
        }
        .alert(languageManager.deleteNoteTitle, isPresented: $showDeleteAlert, presenting: entryToDelete) { entry in
            Button(languageManager.delete, role: .destructive) {
                Task { await appState.deleteEntry(entry) }
            }
            Button(languageManager.cancel, role: .cancel) {}
        } message: { entry in
            Text(languageManager.deleteNoteMessage(entry.title.isEmpty ? languageManager.untitled : entry.title))
        }
    }
}
