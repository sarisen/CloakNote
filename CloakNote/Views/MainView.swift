import SwiftUI

struct MainView: View {
    @Environment(AppState.self) var appState
    @Environment(LanguageManager.self) var languageManager

    var body: some View {
        @Bindable var appState = appState
        NavigationSplitView {
            SidebarView()
        } detail: {
            if let entryId = appState.selectedEntryId,
               let entry = appState.entries.first(where: { $0.id == entryId }) {
                EditorView(entry: entry)
            } else {
                EmptyStateView()
            }
        }
        .navigationTitle(languageManager.appName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    _ = appState.createNewEntry()
                } label: {
                    Image(systemName: "plus")
                }
                .help(languageManager.newNoteShortcut)
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    appState.lock()
                } label: {
                    Image(systemName: "lock.fill")
                }
                .help(languageManager.lockShortcut)
            }
        }
        .alert(languageManager.error, isPresented: Binding(
            get: { appState.errorMessage != nil },
            set: { if !$0 { appState.errorMessage = nil } }
        )) {
            Button(languageManager.ok) { appState.errorMessage = nil }
        } message: {
            Text(appState.errorMessage ?? "")
        }
        .onDeleteCommand {
            if let entry = appState.selectedEntry {
                Task { await appState.deleteEntry(entry) }
            }
        }
        .onAppear { appState.recordActivity() }
        .onChange(of: appState.selectedEntryId) { _, _ in appState.recordActivity() }
    }
}
