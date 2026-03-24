import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) var appState
    @Environment(LanguageManager.self) var languageManager
    @State private var viewModel = SettingsViewModel()
    @State private var showChangePassphrase = false
    @State private var newPassphrase = ""
    @State private var newPassphraseConfirm = ""

    var body: some View {
        TabView {
            githubTab
                .tabItem { Label(languageManager.githubTab, systemImage: "network") }
            securityTab
                .tabItem { Label(languageManager.securityTab, systemImage: "lock.shield") }
            generalTab
                .tabItem { Label(languageManager.generalTab, systemImage: "gearshape") }
            dataTab
                .tabItem { Label(languageManager.dataTab, systemImage: "externaldrive") }
        }
        .frame(minWidth: 480, minHeight: 320)
        .onAppear {
            Task { await viewModel.load(from: appState.syncService, appState: appState) }
        }
    }

    private var githubTab: some View {
        Form {
            Section(languageManager.githubTitle) {
                SecureField(languageManager.personalAccessToken, text: $viewModel.token)
                TextField(languageManager.githubUsername, text: $viewModel.owner)
                TextField(languageManager.repoNameLabel, text: $viewModel.repo)
            }

            Section {
                HStack {
                    Button(languageManager.saveBtn) {
                        Task {
                            try? await viewModel.save(to: appState.syncService, passphrase: appState.passphrase)
                        }
                    }
                    Button(languageManager.testBtn) {
                        Task { await viewModel.testConnection(syncService: appState.syncService) }
                    }
                    .disabled(viewModel.isTestingConnection)
                    if viewModel.isTestingConnection {
                        ProgressView().controlSize(.small)
                    }
                    if let result = viewModel.connectionTestResult {
                        switch result {
                        case .success:
                            Label(languageManager.successLabel, systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        case .failure(let msg):
                            Label(msg, systemImage: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var securityTab: some View {
        Form {
            Section(languageManager.passphraseSection) {
                Button(languageManager.changePassphraseBtn) {
                    showChangePassphrase = true
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .sheet(isPresented: $showChangePassphrase) {
            changePassphraseSheet
        }
    }

    private var changePassphraseSheet: some View {
        VStack(spacing: 16) {
            Text(languageManager.changePassphraseTitle)
                .font(.headline)
            SecureField(languageManager.newPassphraseField, text: $newPassphrase)
                .textFieldStyle(.roundedBorder)
            SecureField(languageManager.confirmField, text: $newPassphraseConfirm)
                .textFieldStyle(.roundedBorder)
            PassphraseStrengthBar(passphrase: newPassphrase)
            HStack {
                Button(languageManager.cancel) {
                    showChangePassphrase = false
                    newPassphrase = ""
                    newPassphraseConfirm = ""
                }
                Spacer()
                Button(languageManager.changeBtn) {
                    if newPassphrase == newPassphraseConfirm && newPassphrase.count >= Constants.minPassphraseLength {
                        appState.passphrase = newPassphrase
                        showChangePassphrase = false
                    }
                }
                .disabled(newPassphrase != newPassphraseConfirm || newPassphrase.count < Constants.minPassphraseLength)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 360)
    }

    private var generalTab: some View {
        @Bindable var bindableLanguageManager = languageManager
        return Form {
            Section(languageManager.themeLabel) {
                Picker(languageManager.themeLabel, selection: $viewModel.colorScheme) {
                    ForEach(SettingsViewModel.AppColorScheme.allCases, id: \.self) { scheme in
                        Text(languageManager.themeLabel(for: scheme)).tag(scheme)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: viewModel.colorScheme) { _, newValue in
                    appState.colorScheme = newValue.colorScheme
                }
            }
            Section(languageManager.autoLockLabel) {
                Picker(languageManager.durationLabel, selection: $viewModel.autoLockInterval) {
                    ForEach(languageManager.autoLockOptions, id: \.1) { label, interval in
                        Text(label).tag(interval)
                    }
                }
                .onChange(of: viewModel.autoLockInterval) { _, newValue in
                    appState.autoLockInterval = newValue
                }
            }
            Section(languageManager.syncIntervalLabel) {
                Picker(languageManager.durationLabel, selection: $viewModel.syncInterval) {
                    ForEach(languageManager.syncIntervalOptions, id: \.1) { label, interval in
                        Text(label).tag(interval)
                    }
                }
                .onChange(of: viewModel.syncInterval) { _, newValue in
                    appState.syncInterval = newValue
                }
            }
            Section(languageManager.languageSection) {
                Picker(languageManager.languageLabel, selection: $bindableLanguageManager.language) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Text(languageManager.languageName(language)).tag(language)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var dataTab: some View {
        Form {
            Section(languageManager.statisticsLabel) {
                LabeledContent(languageManager.totalNotes, value: "\(appState.entries.count)")
                LabeledContent(languageManager.totalWords, value: "\(appState.entries.reduce(0) { $0 + $1.content.split(separator: " ").count })")
            }
            Section(languageManager.dataOperations) {
                Button(languageManager.refreshNotes) {
                    Task { await appState.unlock(passphrase: appState.passphrase) }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
