import SwiftUI

struct EmptyStateView: View {
    @Environment(AppState.self) var appState
    @Environment(LanguageManager.self) var languageManager

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text(languageManager.emptyTitle)
                .font(.title2.bold())
            Text(languageManager.emptySubtitle)
                .foregroundStyle(.secondary)
            Button {
                _ = appState.createNewEntry()
            } label: {
                Label(languageManager.newNote, systemImage: "plus")
            }
            .controlSize(.large)
            .keyboardShortcut("n", modifiers: .command)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
