import Foundation

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case authenticating
    case connected
    case error(String)

    var label: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .authenticating: return "Authenticating..."
        case .connected: return "Connected"
        case .error(let msg): return "Error: \(msg)"
        }
    }
}

class RelayConnection: ObservableObject {
    @Published var state: ConnectionState = .disconnected
    @Published var currentCwd: String?
    @Published var ptyLaunched = false

    var onDataReceived: ((Data) -> Void)?
    var onDirListing: ((String, [DirEntry]) -> Void)?
    var onLaunchResult: ((Bool, String) -> Void)?

    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private var config: ConnectionConfig?
    private var reconnectAttempt = 0
    private let maxReconnectAttempt = 5
    private var intentionalDisconnect = false
    private var connectionID: UUID = UUID()

    func connect(config: ConnectionConfig) {
        guard let url = config.webSocketURL else {
            state = .error("Invalid URL")
            return
        }

        // Cancel previous connection
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        session?.invalidateAndCancel()

        self.config = config
        intentionalDisconnect = false
        state = .connecting

        // New connection ID to ignore stale callbacks
        let thisID = UUID()
        connectionID = thisID

        let session = URLSession(configuration: .default)
        self.session = session

        let task = session.webSocketTask(with: url)
        self.webSocketTask = task
        task.resume()

        authenticate(token: config.authToken, connectionID: thisID)
    }

    func disconnect() {
        intentionalDisconnect = true
        connectionID = UUID()
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        session?.invalidateAndCancel()
        session = nil
        state = .disconnected
        ptyLaunched = false
        currentCwd = nil
    }

    func sendBinary(_ data: Data) {
        webSocketTask?.send(.data(data)) { error in
            if let error {
                print("[relay] send error: \(error.localizedDescription)")
            }
        }
    }

    func sendControl(_ message: ClientMessage) {
        guard let data = message.jsonData else { return }
        let text = String(data: data, encoding: .utf8) ?? ""
        webSocketTask?.send(.string(text)) { error in
            if let error {
                print("[relay] send control error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Private

    private func authenticate(token: String, connectionID: UUID) {
        state = .authenticating
        sendControl(.auth(token: token))
        receiveMessage(connectionID: connectionID)
    }

    private func receiveMessage(connectionID: UUID) {
        webSocketTask?.receive { [weak self] result in
            guard let self, self.connectionID == connectionID else { return }

            switch result {
            case .success(let message):
                self.handleMessage(message)
                self.receiveMessage(connectionID: connectionID)

            case .failure(let error):
                DispatchQueue.main.async {
                    guard self.connectionID == connectionID,
                          !self.intentionalDisconnect else { return }
                    self.state = .error(error.localizedDescription)
                    self.scheduleReconnect()
                }
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .data(let data):
            onDataReceived?(data)

        case .string(let text):
            guard let data = text.data(using: .utf8),
                  let serverMsg = ServerMessage.parse(from: data) else { return }

            DispatchQueue.main.async {
                switch serverMsg {
                case .authResult(let success):
                    if success {
                        self.state = .connected
                        self.reconnectAttempt = 0
                    } else {
                        self.state = .error("Authentication failed")
                        self.webSocketTask?.cancel(with: .normalClosure, reason: nil)
                    }
                case .error(let msg):
                    self.state = .error(msg)
                case .dirListing(let path, let entries):
                    self.onDirListing?(path, entries)
                case .launchResult(let success, let cwd):
                    if success {
                        self.currentCwd = cwd
                        self.ptyLaunched = true
                    }
                    self.onLaunchResult?(success, cwd)
                case .ptyExited:
                    self.ptyLaunched = false
                    self.currentCwd = nil
                }
            }

        @unknown default:
            break
        }
    }

    private func scheduleReconnect() {
        guard !intentionalDisconnect,
              reconnectAttempt < maxReconnectAttempt,
              let config else { return }

        reconnectAttempt += 1
        let delay = min(pow(2.0, Double(reconnectAttempt)), 16.0)
        print("[relay] reconnecting in \(delay)s (attempt \(reconnectAttempt))")

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.connect(config: config)
        }
    }
}
