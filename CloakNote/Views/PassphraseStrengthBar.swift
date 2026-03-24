import SwiftUI

struct PassphraseStrengthBar: View {
    @Environment(LanguageManager.self) var languageManager
    let passphrase: String

    private var strength: PassphraseStrength {
        PassphraseStrength.evaluate(passphrase)
    }

    private var barColor: Color {
        switch strength {
        case .tooShort, .weak: return .red
        case .medium: return .orange
        case .strong: return .green
        case .veryStrong: return .blue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geo.size.width * strength.progress, height: 6)
                        .animation(.easeInOut(duration: 0.3), value: strength.progress)
                }
            }
            .frame(height: 6)
            Text(languageManager.strengthName(strength))
                .font(.caption)
                .foregroundStyle(barColor)
        }
    }
}
