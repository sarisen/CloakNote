import SwiftUI

struct EntryRowView: View {
    @Environment(LanguageManager.self) var languageManager
    let entry: JournalEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(entry.date.dayNumber)
                .font(.title2.monospacedDigit().bold())
                .foregroundStyle(.secondary)
                .frame(width: 32, alignment: .trailing)
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title.isEmpty ? languageManager.untitled : entry.title)
                    .font(.body)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(entry.mood.emoji)
                        .font(.caption)
                    if let firstTag = entry.tags.first {
                        Text("#\(firstTag)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}
