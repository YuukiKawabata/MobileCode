import SwiftUI

struct ShortcutBar: View {
    let relayConnection: RelayConnection

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TerminalShortcut.all) { shortcut in
                    Button {
                        send(shortcut)
                    } label: {
                        Group {
                            if let systemImage = shortcut.systemImage {
                                Image(systemName: systemImage)
                                    .font(.system(size: 16, weight: .medium))
                            } else if let label = shortcut.label {
                                Text(label)
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(minWidth: 44, minHeight: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 48)
    }

    private func send(_ shortcut: TerminalShortcut) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        relayConnection.sendBinary(Data(shortcut.bytes))
    }
}
