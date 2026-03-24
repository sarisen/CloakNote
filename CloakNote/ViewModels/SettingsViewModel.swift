import Foundation
import SwiftUI

@Observable
final class SettingsViewModel {
    var token: String = ""
    var owner: String = ""
    var repo: String = ""
    var isTestingConnection = false
    var connectionTestResult: ConnectionResult? = nil
    var colorScheme: AppColorScheme = .system
    var autoLockInterval: TimeInterval = 1800
    var syncInterval: TimeInterval = Constants.defaultSyncInterval

    enum ConnectionResult {
        case success
        case failure(String)
    }

    enum AppColorScheme: String, CaseIterable {
        case system
        case light
        case dark

        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }

        static func from(_ colorScheme: ColorScheme?) -> Self {
            switch colorScheme {
            case .light: return .light
            case .dark: return .dark
            default: return .system
            }
        }
    }

    func load(from syncService: SyncService, appState: AppState) {
        let config = syncService.currentGitHubConfig()
        token = config?.token ?? ""
        owner = config?.owner ?? ""
        repo = config?.repo ?? ""
        colorScheme = AppColorScheme.from(appState.colorScheme)
        autoLockInterval = appState.autoLockInterval
        syncInterval = appState.syncInterval
    }

    func save(to syncService: SyncService) throws {
        try syncService.saveGitHubConfig(token: token, owner: owner, repo: repo)
    }

    func testConnection(syncService: SyncService) async {
        isTestingConnection = true
        connectionTestResult = nil
        do {
            syncService.github.configure(token: token, owner: owner, repo: repo)
            let ok = try await syncService.github.testConnection()
            connectionTestResult = ok ? .success : .failure(LanguageManager().connectionFailed)
        } catch {
            connectionTestResult = .failure(error.localizedDescription)
        }
        isTestingConnection = false
    }
}
