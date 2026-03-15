import SwiftUI

struct TerminalScreen: View {
    @ObservedObject var relayConnection: RelayConnection
    @State private var showSettings = false
    @State private var displayConfig = DisplayConfig.load()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                TerminalContainer(relayConnection: relayConnection, displayConfig: displayConfig)

                if relayConnection.state == .connected {
                    ShortcutBar(relayConnection: relayConnection)
                }
            }

            // Status + settings overlay
            HStack(spacing: 8) {
                ConnectionStatusBar(state: relayConnection.state)
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gear")
                        .foregroundColor(.white)
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, relayConnection.state == .connected ? 56 : 8)
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showSettings, onDismiss: {
            displayConfig = DisplayConfig.load()
        }) {
            SettingsView(relayConnection: relayConnection)
        }
    }
}
