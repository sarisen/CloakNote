import Foundation

enum Constants {
    static let appName = "CloakNote"
    static let bundleID = "com.cloaknote.app"
    static let githubAPIBase = "https://api.github.com"
    static let pbkdf2Iterations = 600_000
    static let saltLength = 32
    static let defaultRepoName = "cloaknote-notes"
    static let localDraftSaveDelay: TimeInterval = 0.5
    static let defaultSyncInterval: TimeInterval = 300
    static let minPassphraseLength = 16
}
