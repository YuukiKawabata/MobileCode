import SwiftUI

struct TerminalScreen: View {
    @ObservedObject var relayConnection: RelayConnection
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            TerminalContainer(relayConnection: relayConnection)

            HStack {
                ConnectionStatusBar(state: relayConnection.state)
                Spacer()
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
            .padding(.vertical, 4)
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showSettings) {
            SettingsView(relayConnection: relayConnection)
        }
    }
}
