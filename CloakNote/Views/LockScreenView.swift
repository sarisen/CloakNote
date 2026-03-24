import SwiftUI

struct LockScreenView: View {
    @Environment(AppState.self) var appState
    @Environment(LanguageManager.self) var languageManager
    @State private var passphrase = ""
    @State private var showPassphrase = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            BrandMarkView(size: 94)
            Image(systemName: "lock.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(languageManager.lockScreenSubtitle)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if showPassphrase {
                        TextField(languageManager.passphrase, text: $passphrase)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit { Task { await appState.unlock(passphrase: passphrase) } }
                    } else {
                        SecureField(languageManager.passphrase, text: $passphrase)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit { Task { await appState.unlock(passphrase: passphrase) } }
                    }
                    Button {
                        showPassphrase.toggle()
                    } label: {
                        Image(systemName: showPassphrase ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: 360)

                if !passphrase.isEmpty && passphrase.count < Constants.minPassphraseLength {
                    Text(languageManager.minCharsWarning(count: passphrase.count, min: Constants.minPassphraseLength))
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: 360, alignment: .leading)
                }
            }

            if let error = appState.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            }

            if appState.decryptionFailed {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(languageManager.wrongPassphrase)
                        .font(.callout.bold())
                        .foregroundStyle(.orange)
                }
            }

            if appState.isLoading {
                ProgressView(languageManager.opening)
            } else {
                Button(languageManager.unlock) {
                    appState.decryptionFailed = false
                    Task { await appState.unlock(passphrase: passphrase) }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(passphrase.isEmpty)
                .controlSize(.large)
            }
            Spacer()
        }
        .padding(40)
        .frame(minWidth: 480, minHeight: 400)
    }
}
