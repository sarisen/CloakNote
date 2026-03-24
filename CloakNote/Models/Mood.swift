import Foundation

enum Mood: String, Codable, CaseIterable, Identifiable {
    case great
    case good
    case okay
    case bad
    case terrible

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .great: return "😄"
        case .good: return "🙂"
        case .okay: return "😐"
        case .bad: return "😞"
        case .terrible: return "😢"
        }
    }

    var label: String {
        LanguageManager().moodName(self)
    }
}
