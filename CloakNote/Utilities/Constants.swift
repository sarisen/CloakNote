import Foundation

enum Constants {
    static let appName = "CloakNote"
    static let bundleID = "com.cloaknote.app"
    static let githubAPIBase = "https://api.github.com"
    static let pbkdf2Iterations = 600_000
    static let saltLength = 32
    static let defaultRepoName = "cloaknote-notes"
    static let autoSaveDelay: TimeInterval = 2.0
    static let minPassphraseLength = 16
}
