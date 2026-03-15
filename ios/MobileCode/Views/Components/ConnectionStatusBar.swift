import SwiftUI

struct ConnectionStatusBar: View {
    let state: ConnectionState

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
            Text(state.label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private var dotColor: Color {
        switch state {
        case .connected: return .green
        case .connecting, .authenticating: return .yellow
        case .disconnected: return .gray
        case .error: return .red
        }
    }
}
