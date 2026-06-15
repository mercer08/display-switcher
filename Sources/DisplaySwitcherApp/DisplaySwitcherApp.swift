import SwiftUI

@main
struct DisplaySwitcherApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(appState.theme.colorScheme)
                .frame(minWidth: 1040, minHeight: 680)
                .task {
                    await appState.bootstrap()
                }
        }
        .windowResizability(.contentMinSize)

        Settings {
            SettingsView()
                .environmentObject(appState)
                .preferredColorScheme(appState.theme.colorScheme)
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .help) {
                Button(appState.t(.usageGuide)) {
                    appState.showUsageGuide()
                }
                .keyboardShortcut("/", modifiers: [.command])
            }
            CommandMenu(appState.t(.displays)) {
                Button(appState.t(.refresh)) {
                    Task { await appState.refreshDisplays() }
                }
                .keyboardShortcut("r", modifiers: [.command])

                Button(appState.t(.applyGroup)) {
                    appState.requestApplySelectedGroup()
                }
                .keyboardShortcut(.return, modifiers: [.command])
            }
        }
    }
}
