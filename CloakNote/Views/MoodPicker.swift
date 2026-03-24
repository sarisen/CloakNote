import SwiftUI

struct MoodPicker: View {
    @Environment(LanguageManager.self) var languageManager
    @Binding var selectedMood: Mood

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Mood.allCases) { mood in
                Button {
                    selectedMood = mood
                } label: {
                    Text(mood.emoji)
                        .font(.title2)
                        .padding(8)
                        .background(selectedMood == mood ? Color.accentColor.opacity(0.2) : Color.clear)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(languageManager.moodName(mood))
            }
        }
    }
}
