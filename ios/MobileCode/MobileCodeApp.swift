import SwiftUI

@main
struct MobileCodeApp: App {
    @StateObject private var relayConnection = RelayConnection()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            let config = ConnectionConfig.load()
            Group {
                if !config.isConfigured {
                    NavigationView {
                        SettingsView(relayConnection: relayConnection)
                    }
                } else if relayConnection.state == .connected && relayConnection.ptyLaunched {
                    TerminalScreen(relayConnection: relayConnection)
                } else {
                    FolderBrowserView(relayConnection: relayConnection)
                        .onAppear {
                            if relayConnection.state == .disconnected {
                                relayConnection.connect(config: config)
                            }
                        }
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                let cfg = ConnectionConfig.load()
                if newPhase == .active && cfg.isConfigured && relayConnection.state == .disconnected {
                    relayConnection.connect(config: cfg)
                } else if newPhase == .background {
                    relayConnection.disconnect()
                }
            }
        }
    }
}
