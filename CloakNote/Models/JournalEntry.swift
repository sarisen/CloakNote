import Foundation

struct JournalEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var title: String
    var content: String
    var mood: Mood
    var tags: [String]
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        title: String = "",
        content: String = "",
        mood: Mood = .okay,
        tags: [String] = [],
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.content = content
        self.mood = mood
        self.tags = tags
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
