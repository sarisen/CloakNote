import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Codable {
    case turkish = "tr"
    case english = "en"
}

@Observable
final class LanguageManager {
    var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "appLanguage") }
    }

    init() {
        if let saved = UserDefaults.standard.string(forKey: "appLanguage"),
           let lang = AppLanguage(rawValue: saved) {
            language = lang
        } else {
            language = .turkish
        }
    }

    private var tr: Bool { language == .turkish }

    // MARK: - General
    var appName: String { "CloakNote" }
    var ok: String { tr ? "Tamam" : "OK" }
    var cancel: String { tr ? "İptal" : "Cancel" }
    var delete: String { tr ? "Sil" : "Delete" }
    var back: String { tr ? "Geri" : "Back" }
    var continueBtn: String { tr ? "Devam" : "Continue" }
    var getStarted: String { tr ? "Başlayalım" : "Get Started" }
    var lock: String { tr ? "Kilitle" : "Lock" }
    var unlock: String { tr ? "Kilidi Aç" : "Unlock" }
    var quit: String { tr ? "Çıkış" : "Quit" }
    var change: String { tr ? "değiştir" : "change" }
    var opening: String { tr ? "Açılıyor..." : "Opening..." }
    var saving: String { tr ? "Kaydediliyor..." : "Saving..." }
    var synced: String { tr ? "✅ Kaydedildi" : "✅ Saved" }
    var retryBtn: String { tr ? "Tekrar Dene" : "Try Again" }
    var untitled: String { tr ? "Başlıksız" : "Untitled" }
    var words: String { tr ? "kelime" : "words" }
    var error: String { tr ? "Hata" : "Error" }
    var tags: String { tr ? "Etiketler" : "Tags" }
    var search: String { tr ? "Ara..." : "Search..." }
    var notes: String { tr ? "Notlar" : "Notes" }
    var newNoteShortcut: String { tr ? "Yeni Not (⌘N)" : "New Note (⌘N)" }
    var lockShortcut: String { tr ? "Kilitle (⌘L)" : "Lock (⌘L)" }
    var date: String { tr ? "Tarih" : "Date" }
    var passphrase: String { "Passphrase" }
    var personalAccessToken: String { "Personal Access Token" }
    var ownerLabel: String { tr ? "Kullanıcı adı (owner)" : "Username (owner)" }
    var repositoryLabel: String { tr ? "Repo adı" : "Repository name" }
    var passphraseSection: String { "Passphrase" }

    // MARK: - Lock Screen
    var lockScreenSubtitle: String {
        tr ? "Notlarınızı açmak için passphrase'inizi girin."
           : "Enter your passphrase to unlock your notes."
    }
    var wrongPassphrase: String { tr ? "Passphrase yanlış." : "Wrong passphrase." }

    func minCharsWarning(count: Int, min: Int) -> String {
        tr ? "En az \(min) karakter giriniz (\(count)/\(min))"
           : "At least \(min) characters required (\(count)/\(min))"
    }

    // MARK: - Notes
    var newNote: String { tr ? "Yeni Not" : "New Note" }
    var deleteNoteTitle: String { tr ? "Not silinsin mi?" : "Delete note?" }

    func deleteNoteMessage(_ title: String) -> String {
        tr ? "\"\(title)\" silinecek. Bu işlem geri alınamaz."
           : "\"\(title)\" will be deleted. This cannot be undone."
    }
    var deleteFileCommitPrefix: String { tr ? "Notu sil" : "Delete note" }

    // MARK: - Editor
    var titlePlaceholder: String { tr ? "Başlık" : "Title" }
    var moodLabel: String { tr ? "Ruh hali:" : "Mood:" }
    var tagPlaceholder: String { tr ? "+ etiket" : "+ tag" }
    var dateChange: String { tr ? "değiştir" : "change" }

    // MARK: - Empty State
    var emptyTitle: String { tr ? "Yeni bir güne başla" : "Start a new day" }
    var emptySubtitle: String {
        tr ? "Bugünü kaydet — şifreli, sadece senin."
           : "Save today — encrypted, just for you."
    }

    // MARK: - Onboarding
    var chooseLanguageTitle: String { tr ? "Dilini Seç" : "Choose Your Language" }
    var chooseLanguageDescription: String {
        tr ? "Kuruluma başlamadan önce uygulama dilini seçin. Bunu daha sonra Ayarlar'dan değiştirebilirsiniz."
           : "Choose the app language before setup. You can change this later in Settings."
    }
    var languageSelectionHint: String {
        tr ? "Tüm ekranlar seçtiğiniz dille gösterilir."
           : "All screens will be shown in the language you select."
    }
    var setPassphraseTitle: String { tr ? "Passphrase Belirle" : "Set Passphrase" }
    var passphraseDescription: String {
        tr ? "Bu passphrase tüm notlarınızı şifreler. Kaybediniz kalmazsa verilerinize asla erişemezsiniz."
           : "This passphrase encrypts all your notes. If you lose it, your data can never be recovered."
    }
    var passphraseWarning: String {
        tr ? "Bu passphrase'i unutursanız verileriniz asla kurtarılamaz!"
           : "If you forget this passphrase, your data can never be recovered!"
    }
    func passphraseField(_ min: Int) -> String {
        tr ? "Passphrase (min. \(min) karakter)" : "Passphrase (min. \(min) characters)"
    }
    func passphraseMinError(count: Int, min: Int) -> String {
        tr ? "En az \(min) karakter gerekli (\(count)/\(min))"
           : "At least \(min) characters required (\(count)/\(min))"
    }
    var passphraseRepeat: String { tr ? "Passphrase (tekrar)" : "Passphrase (confirm)" }
    var passphraseMismatch: String {
        tr ? "Passphrase'ler eşleşmiyor." : "Passphrases don't match."
    }

    var githubTitle: String { tr ? "GitHub Bağlantısı" : "GitHub Connection" }
    var githubDescription: String {
        tr ? "Şifreli notlar private bir GitHub repo'suna push edilir. GitHub'da sadece okunamaz şifreli blob'lar görünür."
           : "Encrypted notes are pushed to a private GitHub repository. Only unreadable encrypted blobs appear on GitHub."
    }
    var tokenHowTo: String { tr ? "Token nasıl oluşturulur?" : "How to create a token?" }
    var tokenSteps: [String] {
        tr ? [
            "1. github.com → Sağ üst profil fotoğrafı → Settings",
            "2. Sol menü altında: Developer settings",
            "3. Personal access tokens → Tokens (classic)",
            "4. Generate new token (classic)",
            "5. Scope olarak sadece ✅ repo seçmek yeterli"
        ] : [
            "1. github.com → Profile photo (top right) → Settings",
            "2. Bottom of left menu: Developer settings",
            "3. Personal access tokens → Tokens (classic)",
            "4. Generate new token (classic)",
            "5. Only select ✅ repo scope"
        ]
    }
    var repoNameLabel: String { tr ? "Repo adı" : "Repository name" }
    var autoCreateRepo: String {
        tr ? "Repo yoksa otomatik olarak oluştur" : "Auto-create repo if it doesn't exist"
    }
    var privateRepoNote: String {
        tr ? "Private repo olarak oluşturulur. Kimse erişemez."
           : "Created as a private repo. No one else can access it."
    }

    var testConnectionTitle: String { tr ? "Bağlantıyı Test Et" : "Test Connection" }
    var testConnectionDesc: String {
        tr ? "Token ve repo bilgilerinizi doğrulayalım."
           : "Let's verify your token and repository."
    }
    var testing: String { tr ? "Test ediliyor..." : "Testing..." }
    var connectionSuccess: String { tr ? "Bağlantı başarılı!" : "Connection successful!" }
    var letsStart: String { tr ? "Başlayalım!" : "Let's start!" }
    var connectionFailed: String { tr ? "Bağlantı başarısız" : "Connection failed" }
    var usernameError: String {
        tr ? "GitHub kullanıcı adı alınamadı. Token geçerli mi?"
           : "Could not get GitHub username. Is the token valid?"
    }
    func repoNotFound(owner: String, repo: String) -> String {
        tr ? "Repo bulunamadı: \(owner)/\(repo)\n\"Repo yoksa otomatik oluştur\" seçeneğini aktif edin."
           : "Repository not found: \(owner)/\(repo)\nEnable \"Auto-create repo\" option."
    }

    // MARK: - Settings
    var githubTab: String { "GitHub" }
    var securityTab: String { tr ? "Güvenlik" : "Security" }
    var generalTab: String { tr ? "Genel" : "General" }
    var dataTab: String { tr ? "Veri" : "Data" }
    var changePassphraseBtn: String { tr ? "Passphrase Değiştir" : "Change Passphrase" }
    var changePassphraseTitle: String { tr ? "Passphrase Değiştir" : "Change Passphrase" }
    var newPassphraseField: String { tr ? "Yeni Passphrase" : "New Passphrase" }
    var confirmField: String { tr ? "Tekrar" : "Confirm" }
    var changeBtn: String { tr ? "Değiştir" : "Change" }
    var saveBtn: String { tr ? "Kaydet" : "Save" }
    var testBtn: String { tr ? "Bağlantıyı Test Et" : "Test Connection" }
    var successLabel: String { tr ? "Başarılı" : "Success" }
    var themeLabel: String { tr ? "Tema" : "Theme" }
    var autoLockLabel: String { tr ? "Otomatik Kilit" : "Auto-Lock" }
    var syncIntervalLabel: String { tr ? "Senkronizasyon Aralığı" : "Sync Interval" }
    var durationLabel: String { tr ? "Süre" : "Duration" }
    var statisticsLabel: String { tr ? "İstatistikler" : "Statistics" }
    var totalNotes: String { tr ? "Toplam Not" : "Total Notes" }
    var totalWords: String { tr ? "Toplam Kelime" : "Total Words" }
    var dataOperations: String { tr ? "Veri İşlemleri" : "Data Operations" }
    var refreshNotes: String { tr ? "Tüm Notları Yenile" : "Refresh All Notes" }
    var githubUsername: String { tr ? "Kullanıcı Adı (owner)" : "Username (owner)" }
    var languageLabel: String { tr ? "Dil" : "Language" }
    var languageSection: String { tr ? "Dil" : "Language" }
    var githubTokenPlaceholder: String { "\(personalAccessToken) (ghp_...)" }

    var autoLockOptions: [(String, TimeInterval)] {
        tr ? [("5 dakika", 300), ("15 dakika", 900), ("30 dakika", 1800), ("1 saat", 3600), ("Asla", 0)]
           : [("5 minutes", 300), ("15 minutes", 900), ("30 minutes", 1800), ("1 hour", 3600), ("Never", 0)]
    }

    var syncIntervalOptions: [(String, TimeInterval)] {
        tr ? [("5 dakika", 300), ("15 dakika", 900), ("30 dakika", 1800), ("1 saat", 3600)]
           : [("5 minutes", 300), ("15 minutes", 900), ("30 minutes", 1800), ("1 hour", 3600)]
    }

    var themeOptions: [(String, SettingsViewModel.AppColorScheme)] {
        tr ? [("Sistem", .system), ("Açık", .light), ("Koyu", .dark)]
           : [("System", .system), ("Light", .light), ("Dark", .dark)]
    }

    func themeLabel(for scheme: SettingsViewModel.AppColorScheme) -> String {
        themeOptions.first(where: { $0.1 == scheme })?.0 ?? scheme.rawValue
    }

    func languageName(_ language: AppLanguage) -> String {
        switch language {
        case .turkish:
            return tr ? "Türkçe" : "Turkish"
        case .english:
            return tr ? "İngilizce" : "English"
        }
    }

    // MARK: - Menu Bar
    var menuBarLocked: String { tr ? "CloakNote — Kilitli" : "CloakNote — Locked" }
    func menuBarNotes(_ count: Int) -> String {
        tr ? "CloakNote — \(count) not" : "CloakNote — \(count) notes"
    }
    var openNotes: String { tr ? "Notları Aç" : "Open Notes" }
    var saveCommitPrefix: String { "CloakNote" }
    var privateRepoDescription: String {
        tr ? "CloakNote sifreli not deposu - burada okunabilir icerik yok"
           : "CloakNote encrypted notes repository - nothing readable here"
    }

    // MARK: - Mood labels
    func moodName(_ mood: Mood) -> String {
        switch (mood, language) {
        case (.great, .turkish): return "Harika"
        case (.great, .english): return "Great"
        case (.good, .turkish): return "İyi"
        case (.good, .english): return "Good"
        case (.okay, .turkish): return "Normal"
        case (.okay, .english): return "Okay"
        case (.bad, .turkish): return "Kötü"
        case (.bad, .english): return "Bad"
        case (.terrible, .turkish): return "Berbat"
        case (.terrible, .english): return "Terrible"
        }
    }

    // MARK: - PassphraseStrength labels
    func strengthName(_ s: PassphraseStrength) -> String {
        switch (s, language) {
        case (.tooShort, .turkish): return "Çok kısa"
        case (.tooShort, .english): return "Too short"
        case (.weak, .turkish): return "Zayıf"
        case (.weak, .english): return "Weak"
        case (.medium, .turkish): return "Orta"
        case (.medium, .english): return "Medium"
        case (.strong, .turkish): return "Güçlü"
        case (.strong, .english): return "Strong"
        case (.veryStrong, .turkish): return "Çok güçlü"
        case (.veryStrong, .english): return "Very strong"
        }
    }

    // MARK: - Error messages
    func decryptionError(_ detail: String) -> String {
        tr ? "Şifre çözme hatası: Passphrase yanlış olabilir.\n(\(detail))"
           : "Decryption failed: Passphrase may be incorrect.\n(\(detail))"
    }
    func deleteError(_ detail: String) -> String {
        tr ? "Silme hatası: \(detail)" : "Deletion failed: \(detail)"
    }
    func genericError(_ detail: String) -> String {
        tr ? "Hata: \(detail)" : "Error: \(detail)"
    }
    var invalidEncryptedPayload: String {
        tr ? "Sifreli veri gecersiz" : "Invalid encrypted payload"
    }
    var decryptionFailedMessage: String {
        tr ? "Sifre cozulmedi - passphrase yanlis olabilir"
           : "Decryption failed - passphrase may be incorrect"
    }
    func keychainSaveError(_ status: OSStatus) -> String {
        tr ? "Keychain kayit hatasi: \(status)" : "Keychain save error: \(status)"
    }
    func keychainDeleteError(_ status: OSStatus) -> String {
        tr ? "Keychain silme hatasi: \(status)" : "Keychain delete error: \(status)"
    }
    var invalidGitHubFileContent: String {
        tr ? "GitHub dosya icerigi gecersiz" : "Invalid GitHub file content"
    }
    func gitHubAPIError(code: Int, message: String) -> String {
        tr ? "GitHub API hatasi (\(code)): \(message)"
           : "GitHub API error (\(code)): \(message)"
    }
    func unresolvedConflictError(attempts: Int) -> String {
        tr ? "\(attempts) denemeden sonra cakisma cozulmedi"
           : "Conflict could not be resolved after \(attempts) attempts"
    }

    // MARK: - Formatting
    func locale(for language: AppLanguage? = nil) -> Locale {
        Locale(identifier: (language ?? self.language) == .turkish ? "tr_TR" : "en_US")
    }

    func fullDateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy, EEEE"
        formatter.locale = locale()
        return formatter.string(from: date)
    }

    func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = locale()
        return formatter.string(from: date)
    }
}
