import Foundation

// Client → Server
enum ClientMessage {
    case auth(token: String)
    case resize(cols: Int, rows: Int)

    var jsonData: Data? {
        let dict: [String: Any]
        switch self {
        case .auth(let token):
            dict = ["type": "auth", "token": token]
        case .resize(let cols, let rows):
            dict = ["type": "resize", "cols": cols, "rows": rows]
        }
        return try? JSONSerialization.data(withJSONObject: dict)
    }
}

// Server → Client
enum ServerMessage {
    case authResult(success: Bool)
    case error(message: String)

    static func parse(from data: Data) -> ServerMessage? {
        guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = dict["type"] as? String else {
            return nil
        }
        switch type {
        case "auth_result":
            let success = dict["success"] as? Bool ?? false
            return .authResult(success: success)
        case "error":
            let message = dict["message"] as? String ?? "unknown error"
            return .error(message: message)
        default:
            return nil
        }
    }
}
