import SwiftUI

struct DatePickerPopover: View {
    @Environment(LanguageManager.self) var languageManager
    @Binding var date: Date
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 12) {
            DatePicker(
                languageManager.date,
                selection: $date,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()

            Button(languageManager.ok) {
                isPresented = false
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding()
        .frame(minWidth: 300)
    }
}
