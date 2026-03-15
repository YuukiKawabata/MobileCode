import SwiftUI
import SwiftTerm

struct TerminalContainer: UIViewRepresentable {
    let relayConnection: RelayConnection
    let displayConfig: DisplayConfig

    func makeUIView(context: Context) -> TerminalView {
        let tv = TerminalView()
        tv.terminalDelegate = context.coordinator
        tv.inputAccessoryView = nil
        _ = tv.becomeFirstResponder()

        let fontSize = displayConfig.fontSize
        tv.font = UIFont(name: "Menlo", size: fontSize) ?? UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)

        // Dark terminal appearance
        tv.nativeBackgroundColor = .black
        tv.nativeForegroundColor = .white

        // Wire up incoming data from server
        relayConnection.onDataReceived = { data in
            let bytes = ArraySlice([UInt8](data))
            DispatchQueue.main.async {
                tv.feed(byteArray: bytes)
            }
        }

        return tv
    }

    func updateUIView(_ uiView: TerminalView, context: Context) {
        let fontSize = displayConfig.fontSize
        if uiView.font.pointSize != fontSize {
            let newFont = UIFont(name: "Menlo", size: fontSize) ?? UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
            uiView.font = newFont
            // Force SwiftTerm to recalculate cols/rows and send resize to server
            uiView.setNeedsLayout()
            uiView.layoutIfNeeded()
        }
        uiView.inputAccessoryView = nil
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(relayConnection: relayConnection)
    }

    class Coordinator: NSObject, TerminalViewDelegate {
        let relayConnection: RelayConnection

        init(relayConnection: RelayConnection) {
            self.relayConnection = relayConnection
        }

        func send(source: TerminalView, data: ArraySlice<UInt8>) {
            let d = Data(data)
            relayConnection.sendBinary(d)
        }

        func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {
            relayConnection.sendControl(.resize(cols: newCols, rows: newRows))
        }

        func scrolled(source: TerminalView, position: Double) {}
        func setTerminalTitle(source: TerminalView, title: String) {}
        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}
        func clipboardCopy(source: TerminalView, content: Data) {}
        func rangeChanged(source: TerminalView, startY: Int, endY: Int) {}
        func requestOpenLink(source: TerminalView, link: String, params: [String : String]) {}
        func bell(source: TerminalView) {}
        func iTermContent(source: TerminalView, content: Data) {}
    }
}
