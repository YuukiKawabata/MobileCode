import UIKit

struct DisplayConfig: Codable {
    var fontSize: CGFloat

    static let defaultConfig = DisplayConfig(fontSize: 13)

    // MARK: - UserDefaults Persistence

    private static let storageKey = "DisplayConfig"

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    static func load() -> DisplayConfig {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let config = try? JSONDecoder().decode(DisplayConfig.self, from: data) else {
            return .defaultConfig
        }
        return config
    }

    /// Calculate terminal columns and rows based on screen size and font
    func terminalSize() -> (cols: Int, rows: Int) {
        let font = UIFont(name: "Menlo", size: fontSize) ?? UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        // Measure the width of a single character
        let charSize = ("W" as NSString).size(withAttributes: [.font: font])
        let screenWidth = UIScreen.main.bounds.width
        // Reserve space for shortcut bar (46pt) and safe area
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first { $0.isKeyWindow }
        let safeBottom = keyWindow?.safeAreaInsets.bottom ?? 0
        let screenHeight = UIScreen.main.bounds.height - safeBottom - 46
        let cols = max(Int(screenWidth / charSize.width), 20)
        let rows = max(Int(screenHeight / charSize.height), 10)
        return (cols, rows)
    }
}
