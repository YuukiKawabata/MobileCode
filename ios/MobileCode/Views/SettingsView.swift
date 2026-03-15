import SwiftUI

struct SettingsView: View {
    @ObservedObject var relayConnection: RelayConnection
    @Environment(\.dismiss) private var dismiss

    @State private var serverURL: String = ""
    @State private var authToken: String = ""
    @State private var fontSize: CGFloat = DisplayConfig.defaultConfig.fontSize

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

                Section("Display") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Font Size")
                            Spacer()
                            Text("\(Int(fontSize))pt")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $fontSize, in: 9...20, step: 1) {
                            Text("Font Size")
                        }
                        .onChange(of: fontSize) {
                            DisplayConfig(fontSize: fontSize).save()
                        }
                        Text("The quick brown fox jumps over the lazy dog")
                            .font(.system(size: fontSize, design: .monospaced))
                            .foregroundColor(.secondary)
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
            let connConfig = ConnectionConfig.load()
            serverURL = connConfig.serverURL
            authToken = connConfig.authToken
            fontSize = DisplayConfig.load().fontSize
        }
    }
}
