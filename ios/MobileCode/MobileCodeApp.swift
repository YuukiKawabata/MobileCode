import SwiftUI

@main
struct MobileCodeApp: App {
    @StateObject private var relayConnection = RelayConnection()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSettings = false

    var body: some Scene {
        WindowGroup {
            let config = ConnectionConfig.load()
            Group {
                if config.isConfigured {
                    TerminalScreen(relayConnection: relayConnection)
                        .onAppear {
                            if relayConnection.state == .disconnected {
                                relayConnection.connect(config: config)
                            }
                        }
                } else {
                    NavigationView {
                        SettingsView(relayConnection: relayConnection)
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
