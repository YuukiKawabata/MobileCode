import SwiftUI

struct ShortcutBar: View {
    let relayConnection: RelayConnection
    @State private var showExtended = false

    private var shortcuts: [TerminalShortcut] {
        showExtended ? TerminalShortcut.extended : TerminalShortcut.primary
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(shortcuts) { shortcut in
                Button {
                    send(shortcut)
                } label: {
                    Group {
                        if let systemImage = shortcut.systemImage {
                            Image(systemName: systemImage)
                                .font(.system(size: 15, weight: .medium))
                        } else if let label = shortcut.label {
                            Text(label)
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showExtended.toggle()
                }
            } label: {
                Image(systemName: showExtended ? "chevron.left" : "ellipsis")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 36)
                    .frame(minHeight: 40)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
        .frame(height: 46)
    }

    private func send(_ shortcut: TerminalShortcut) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        relayConnection.sendBinary(Data(shortcut.bytes))
    }
}
