//
//  CloakNoteApp.swift
//  CloakNote
//
//  Created by Serafettin Sarisen on 23.03.2026.
//

import SwiftUI

@main
struct CloakNoteApp: App {
    @State private var appState = AppState()
    @State private var languageManager = LanguageManager()

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environment(appState)
                .environment(languageManager)
                .preferredColorScheme(appState.colorScheme)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(languageManager.newNote) {
                    _ = appState.createNewEntry()
                }
                .keyboardShortcut("n", modifiers: .command)
                .disabled(appState.isLocked)
            }
            CommandGroup(after: .appInfo) {
                Button(languageManager.lock) {
                    appState.lock()
                }
                .keyboardShortcut("l", modifiers: .command)
                Button(languageManager.saveBtn) {
                    NotificationCenter.default.post(name: .saveCurrentNote, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(appState.isLocked)
            }
        }

        MenuBarExtra {
            MenuBarView()
                .environment(appState)
                .environment(languageManager)
        } label: {
            Image(systemName: appState.isLocked ? "lock.fill" : "lock.open.fill")
        }

        Settings {
            SettingsView()
                .environment(appState)
                .environment(languageManager)
        }
    }
}

struct ContentView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        Group {
            if appState.isFirstLaunch {
                OnboardingView()
            } else if appState.isLocked {
                LockScreenView()
            } else {
                MainView()
            }
        }
        .onAppear {
            appState.checkFirstLaunch()
        }
    }
}

struct MenuBarView: View {
    @Environment(AppState.self) var appState
    @Environment(LanguageManager.self) var languageManager
    @Environment(\.openWindow) var openWindow

    var body: some View {
        VStack(spacing: 4) {
            if appState.isLocked {
                Text(languageManager.menuBarLocked)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(languageManager.menuBarNotes(appState.entries.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button(languageManager.openNotes) {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }

            if !appState.isLocked {
                Button(languageManager.lock) {
                    appState.lock()
                }
            }

            Divider()

            Button(languageManager.quit) {
                NSApp.terminate(nil)
            }
        }
        .padding(4)
    }
}
