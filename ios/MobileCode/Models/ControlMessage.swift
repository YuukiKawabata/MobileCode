import Foundation

// Client → Server
enum ClientMessage {
    case auth(token: String)
    case resize(cols: Int, rows: Int)
    case listDir(path: String)
    case launch(cwd: String, cols: Int, rows: Int)

    var jsonData: Data? {
        let dict: [String: Any]
        switch self {
        case .auth(let token):
            dict = ["type": "auth", "token": token]
        case .resize(let cols, let rows):
            dict = ["type": "resize", "cols": cols, "rows": rows]
        case .listDir(let path):
            dict = ["type": "list_dir", "path": path]
        case .launch(let cwd, let cols, let rows):
            dict = ["type": "launch", "cwd": cwd, "cols": cols, "rows": rows]
        }
        return try? JSONSerialization.data(withJSONObject: dict)
    }
}

struct DirEntry: Identifiable {
    let name: String
    let isDir: Bool
    var id: String { name }
}

// Server → Client
enum ServerMessage {
    case authResult(success: Bool)
    case error(message: String)
    case dirListing(path: String, entries: [DirEntry])
    case launchResult(success: Bool, cwd: String)
    case ptyExited

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
        case "dir_listing":
            let path = dict["path"] as? String ?? ""
            let rawEntries = dict["entries"] as? [[String: Any]] ?? []
            let entries = rawEntries.map { entry in
                DirEntry(
                    name: entry["name"] as? String ?? "",
                    isDir: entry["isDir"] as? Bool ?? false
                )
            }
            return .dirListing(path: path, entries: entries)
        case "launch_result":
            let success = dict["success"] as? Bool ?? false
            let cwd = dict["cwd"] as? String ?? ""
            return .launchResult(success: success, cwd: cwd)
        case "pty_exited":
            return .ptyExited
        default:
            return nil
        }
    }
}
