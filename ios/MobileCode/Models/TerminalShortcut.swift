import Foundation

struct TerminalShortcut: Identifiable {
    let id: String
    let label: String?
    let systemImage: String?
    let bytes: [UInt8]

    static let primary: [TerminalShortcut] = [
        TerminalShortcut(id: "shift-tab", label: "S-Tab", systemImage: nil, bytes: [0x1b, 0x5b, 0x5a]),
        TerminalShortcut(id: "ctrl-c", label: "^C", systemImage: nil, bytes: [0x03]),
        TerminalShortcut(id: "esc", label: "Esc", systemImage: nil, bytes: [0x1b]),
        TerminalShortcut(id: "tab", label: "Tab", systemImage: nil, bytes: [0x09]),
        TerminalShortcut(id: "up", label: nil, systemImage: "chevron.up", bytes: [0x1b, 0x5b, 0x41]),
        TerminalShortcut(id: "down", label: nil, systemImage: "chevron.down", bytes: [0x1b, 0x5b, 0x42]),
        TerminalShortcut(id: "ctrl-l", label: "^L", systemImage: nil, bytes: [0x0c]),
    ]

    static let extended: [TerminalShortcut] = [
        TerminalShortcut(id: "ctrl-r", label: "^R", systemImage: nil, bytes: [0x12]),
        TerminalShortcut(id: "ctrl-b", label: "^B", systemImage: nil, bytes: [0x02]),
        TerminalShortcut(id: "ctrl-z", label: "^Z", systemImage: nil, bytes: [0x1a]),
        TerminalShortcut(id: "ctrl-o", label: "^O", systemImage: nil, bytes: [0x0f]),
    ]
}
