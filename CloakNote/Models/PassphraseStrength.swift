import Foundation

enum PassphraseStrength {
    case tooShort
    case weak
    case medium
    case strong
    case veryStrong

    var label: String {
        LanguageManager().strengthName(self)
    }

    var color: String {
        switch self {
        case .tooShort, .weak: return "red"
        case .medium: return "orange"
        case .strong: return "green"
        case .veryStrong: return "blue"
        }
    }

    var progress: Double {
        switch self {
        case .tooShort: return 0.1
        case .weak: return 0.25
        case .medium: return 0.5
        case .strong: return 0.75
        case .veryStrong: return 1.0
        }
    }

    static func evaluate(_ passphrase: String) -> PassphraseStrength {
        guard passphrase.count >= 4 else { return .tooShort }

        var charsetSize = 0
        if passphrase.range(of: "[a-z]", options: .regularExpression) != nil { charsetSize += 26 }
        if passphrase.range(of: "[A-Z]", options: .regularExpression) != nil { charsetSize += 26 }
        if passphrase.range(of: "[0-9]", options: .regularExpression) != nil { charsetSize += 10 }
        if passphrase.range(of: "[^a-zA-Z0-9]", options: .regularExpression) != nil { charsetSize += 32 }

        let entropy = Double(passphrase.count) * log2(Double(max(charsetSize, 1)))

        if entropy < 28 { return .tooShort }
        if entropy < 45 { return .weak }
        if entropy < 60 { return .medium }
        if entropy < 80 { return .strong }
        return .veryStrong
    }
}
