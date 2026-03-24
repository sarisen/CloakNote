import SwiftUI

struct EditorView: View {
    @Environment(AppState.self) var appState
    @Environment(LanguageManager.self) var languageManager
    let entry: JournalEntry

    @State private var viewModel: EditorViewModel

    init(entry: JournalEntry) {
        self.entry = entry
        self._viewModel = State(initialValue: EditorViewModel(entry: entry))
    }

    var syncStatusText: String {
        switch appState.syncStatus {
        case .idle: return ""
        case .syncing: return languageManager.saving
        case .synced: return languageManager.synced
        case .error(let msg): return "⚠️ \(msg)"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(languageManager.fullDateString(for: viewModel.entry.date))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button(languageManager.dateChange) {
                    viewModel.showDatePicker = true
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
                .font(.subheadline)
                .popover(isPresented: $viewModel.showDatePicker) {
                    DatePickerPopover(
                        date: Binding(
                            get: { viewModel.entry.date },
                            set: { viewModel.updateDate($0) }
                        ),
                        isPresented: $viewModel.showDatePicker
                    )
                }
                Spacer()
            }
            .padding([.horizontal, .top])

            Divider().padding(.top, 8)

            // Title
            TextField(languageManager.titlePlaceholder, text: Binding(
                get: { viewModel.entry.title },
                set: {
                    viewModel.updateTitle($0)
                    viewModel.scheduleAutoSave(appState: appState)
                }
            ))
            .textFieldStyle(.plain)
            .font(.title3.bold())
            .padding(.horizontal)
            .padding(.top, 12)

            // Mood
            HStack {
                Text(languageManager.moodLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                MoodPicker(selectedMood: Binding(
                    get: { viewModel.entry.mood },
                    set: {
                        viewModel.updateMood($0)
                        viewModel.scheduleAutoSave(appState: appState)
                    }
                ))
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Divider().padding(.top, 8)

            // Content
            TextEditor(text: Binding(
                get: { viewModel.entry.content },
                set: {
                    viewModel.updateContent($0)
                    viewModel.scheduleAutoSave(appState: appState)
                }
            ))
            .font(.body)
            .padding(.horizontal, 12)

            Divider()

            // Footer
            HStack(spacing: 8) {
                ForEach(viewModel.entry.tags, id: \.self) { tag in
                    HStack(spacing: 2) {
                        Text("#\(tag)")
                            .font(.caption)
                        Button {
                            viewModel.removeTag(tag)
                            viewModel.scheduleAutoSave(appState: appState)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 8))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Capsule())
                }

                HStack(spacing: 4) {
                    TextField(languageManager.tagPlaceholder, text: $viewModel.newTag)
                        .textFieldStyle(.plain)
                        .frame(width: 60)
                        .font(.caption)
                        .onSubmit {
                            viewModel.addTag()
                            viewModel.scheduleAutoSave(appState: appState)
                        }
                }

                Spacer()
                Text("\(viewModel.wordCount) \(languageManager.words)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(syncStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .onAppear {
            viewModel = EditorViewModel(entry: entry)
        }
        .onChange(of: entry.id) { _, _ in
            viewModel.saveIfDirty(appState: appState)
            viewModel = EditorViewModel(entry: entry)
        }
        .keyboardShortcut("s", modifiers: .command)
        .onReceive(NotificationCenter.default.publisher(for: .saveCurrentNote)) { _ in
            Task { await appState.saveEntry(viewModel.entry) }
        }
    }
}

extension Notification.Name {
    static let saveCurrentNote = Notification.Name("saveCurrentNote")
}
