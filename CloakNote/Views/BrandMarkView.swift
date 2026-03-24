import SwiftUI

struct BrandMarkView: View {
    @Environment(LanguageManager.self) var languageManager
    let size: CGFloat
    var showsTitle = true

    var body: some View {
        VStack(spacing: 14) {
            Image("BrandLogo")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
                .shadow(color: .black.opacity(0.14), radius: size * 0.12, y: size * 0.05)

            if showsTitle {
                Text(languageManager.appName)
                    .font(.system(size: max(18, size * 0.22), weight: .bold, design: .rounded))
            }
        }
        .accessibilityElement(children: .combine)
    }
}
