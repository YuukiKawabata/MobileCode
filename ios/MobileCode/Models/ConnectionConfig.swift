import Foundation

struct ConnectionConfig: Codable {
    var serverURL: String
    var authToken: String

    var isConfigured: Bool {
        !serverURL.isEmpty && !authToken.isEmpty
    }

    var webSocketURL: URL? {
        URL(string: serverURL)
    }

    static let defaultConfig = ConnectionConfig(serverURL: "", authToken: "")

    // MARK: - UserDefaults Persistence

    private static let storageKey = "ConnectionConfig"

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    static func load() -> ConnectionConfig {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let config = try? JSONDecoder().decode(ConnectionConfig.self, from: data) else {
            return .defaultConfig
        }
        return config
    }
}
