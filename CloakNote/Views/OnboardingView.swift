import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) var appState
    @Environment(LanguageManager.self) var languageManager
    @State private var currentStep = 0
    @State private var passphrase = ""
    @State private var passphraseConfirm = ""
    @State private var token = ""
    @State private var owner = ""
    @State private var repo = Constants.defaultRepoName
    @State private var createRepoIfMissing = true
    @State private var isTesting = false
    @State private var testResult: TestResult? = nil
    @State private var errorMessage: String? = nil

    enum TestResult {
        case success
        case failure(String)
    }

    var passphraseValid: Bool {
        passphrase.count >= Constants.minPassphraseLength && passphrase == passphraseConfirm
    }

    var body: some View {
        VStack(spacing: 0) {
            // Steps header
            HStack(spacing: 0) {
                ForEach(0..<4) { step in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(step <= currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                        if step < 3 {
                            Rectangle()
                                .fill(step < currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                                .frame(height: 1)
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 32)

            Spacer()

            Group {
                switch currentStep {
                case 0: stepLanguage
                case 1: stepPassphrase
                case 2: stepGitHub
                case 3: stepTest
                default: EmptyView()
                }
            }
            .frame(maxWidth: 420)
            .padding(.horizontal, 40)

            Spacer()

            HStack {
                if currentStep > 0 {
                    Button(languageManager.back) { currentStep -= 1 }
                }
                Spacer()
                if currentStep < 3 {
                    Button(currentStep == 0 ? languageManager.getStarted : languageManager.continueBtn) {
                        if currentStep == 1 {
                            guard passphraseValid else { return }
                            appState.passphrase = passphrase
                        }
                        currentStep += 1
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(currentStep == 1 && !passphraseValid)
                }
            }
            .padding(24)
        }
        .frame(minWidth: 520, minHeight: 480)
    }

    private var stepLanguage: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Spacer()
                BrandMarkView(size: 88, showsTitle: false)
                Spacer()
            }
            .padding(.bottom, 6)

            Text(languageManager.chooseLanguageTitle)
                .font(.title2.bold())

            Text(languageManager.chooseLanguageDescription)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Button {
                        languageManager.language = language
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: languageManager.language == language ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(languageManager.language == language ? Color.accentColor : .secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(languageManager.languageName(language))
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(languageManager.languageCode(language))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(languageManager.languageSelectionHint)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var stepPassphrase: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()
                BrandMarkView(size: 72, showsTitle: false)
                Spacer()
            }
            .padding(.bottom, 2)

            Text(languageManager.setPassphraseTitle)
                .font(.title2.bold())
            Text(languageManager.passphraseDescription)
                .foregroundStyle(.secondary)

            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(languageManager.passphraseWarning)
                    .font(.callout)
                    .foregroundStyle(.orange)
            }
            .padding(10)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            SecureField(languageManager.passphraseField(Constants.minPassphraseLength), text: $passphrase)
                .textFieldStyle(.roundedBorder)

            if !passphrase.isEmpty && passphrase.count < Constants.minPassphraseLength {
                Text(languageManager.passphraseMinError(count: passphrase.count, min: Constants.minPassphraseLength))
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            SecureField(languageManager.passphraseRepeat, text: $passphraseConfirm)
                .textFieldStyle(.roundedBorder)

            PassphraseStrengthBar(passphrase: passphrase)

            if !passphraseConfirm.isEmpty && passphrase != passphraseConfirm {
                Text(languageManager.passphraseMismatch)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
    }

    private var stepGitHub: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()
                BrandMarkView(size: 72, showsTitle: false)
                Spacer()
            }
            .padding(.bottom, 2)

            Text(languageManager.githubTitle)
                .font(.title2.bold())
            Text(languageManager.githubDescription)
                .foregroundStyle(.secondary)

            // Token info box
            VStack(alignment: .leading, spacing: 6) {
                Label(languageManager.tokenHowTo, systemImage: "questionmark.circle.fill")
                    .font(.callout.bold())
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(languageManager.tokenSteps, id: \.self) { step in
                        Text(step)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(Color.blue.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            SecureField(languageManager.githubTokenPlaceholder, text: $token)
                .textFieldStyle(.roundedBorder)

            TextField(languageManager.repoNameLabel, text: $repo)
                .textFieldStyle(.roundedBorder)

            HStack(alignment: .top, spacing: 8) {
                Toggle("", isOn: $createRepoIfMissing)
                    .labelsHidden()
                    .toggleStyle(.checkbox)
                VStack(alignment: .leading, spacing: 2) {
                    Text(languageManager.autoCreateRepo)
                        .font(.callout)
                    Text(languageManager.privateRepoNote)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var stepTest: some View {
        VStack(spacing: 20) {
            BrandMarkView(size: 72, showsTitle: false)

            Text(languageManager.testConnectionTitle)
                .font(.title2.bold())

            Text(languageManager.testConnectionDesc)
                .foregroundStyle(.secondary)

            if isTesting {
                ProgressView(languageManager.testing)
            } else if let result = testResult {
                switch result {
                case .success:
                    Label(languageManager.connectionSuccess, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.headline)
                    Button(languageManager.letsStart) {
                        completeOnboarding()
                    }
                    .keyboardShortcut(.defaultAction)
                    .controlSize(.large)
                case .failure(let msg):
                    Label(languageManager.connectionFailed, systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.headline)
                    Text(msg)
                        .font(.callout)
                        .foregroundStyle(.red.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button(languageManager.retryBtn) { Task { await runTest() } }
                }
            } else {
                Button(languageManager.testBtn) {
                    Task { await runTest() }
                }
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func runTest() async {
        isTesting = true
        testResult = nil
        do {
            // 1. Token doğrulandıktan sonra owner'ı otomatik al
            appState.syncService.github.configure(token: token, owner: owner, repo: repo)
            if owner.trimmingCharacters(in: .whitespaces).isEmpty {
                let detectedOwner = try await appState.syncService.github.currentUser()
                guard !detectedOwner.isEmpty else {
                    testResult = .failure(languageManager.usernameError)
                    isTesting = false
                    return
                }
                owner = detectedOwner
                appState.syncService.github.configure(token: token, owner: owner, repo: repo)
            }

            // 2. Repo yoksa oluştur
            if createRepoIfMissing {
                let exists = try await appState.syncService.github.testConnection()
                if !exists {
                    try await appState.syncService.github.createRepo(name: repo)
                    // Repo oluşturuldu, kısa bekleme
                    try await Task.sleep(for: .seconds(1))
                }
            }

            // 3. Bağlantıyı test et
            let ok = try await appState.syncService.github.testConnection()
            if ok {
                testResult = .success
            } else {
                testResult = .failure(languageManager.repoNotFound(owner: owner, repo: repo))
            }
        } catch {
            testResult = .failure(error.localizedDescription)
        }
        isTesting = false
    }

    private func completeOnboarding() {
        Task {
            try? await appState.syncService.saveGitHubConfig(token: token, owner: owner, repo: repo, passphrase: appState.passphrase)
            await MainActor.run {
                appState.isFirstLaunch = false
                appState.isLocked = false
            }
        }
    }
}
