import Foundation

extension Date {
    var dayNumber: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: self)
    }

    var fullDateString: String {
        let languageManager = LanguageManager()
        let f = DateFormatter()
        f.dateFormat = "d MMMM yyyy, EEEE"
        f.locale = languageManager.locale()
        return f.string(from: self)
    }

    var shortDateString: String {
        let languageManager = LanguageManager()
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        f.locale = languageManager.locale()
        return f.string(from: self)
    }
}

extension Data {
    var base64URLEncoded: String {
        base64EncodedString()
    }
}

extension JSONEncoder {
    static let cloakNote: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()
}
