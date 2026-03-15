import SwiftUI

struct SettingsView: View {
    @ObservedObject var relayConnection: RelayConnection
    @Environment(\.dismiss) private var dismiss

    @State private var serverURL: String = ""
    @State private var authToken: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Server") {
                    TextField("URL (e.g. ws://192.168.1.5:8765)", text: $serverURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)

                    SecureField("Auth Token", text: $authToken)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section {
                    Button("Connect") {
                        let config = ConnectionConfig(serverURL: serverURL, authToken: authToken)
                        config.save()
                        relayConnection.disconnect()
                        relayConnection.connect(config: config)
                        dismiss()
                    }
                    .disabled(serverURL.isEmpty || authToken.isEmpty)
                }

                if relayConnection.state == .connected {
                    Section {
                        Button("Disconnect", role: .destructive) {
                            relayConnection.disconnect()
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            let config = ConnectionConfig.load()
            serverURL = config.serverURL
            authToken = config.authToken
        }
    }
}
