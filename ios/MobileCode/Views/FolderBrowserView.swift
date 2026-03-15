import SwiftUI

struct FolderBrowserView: View {
    @ObservedObject var relayConnection: RelayConnection

    @State private var currentPath: String = ""
    @State private var entries: [DirEntry] = []
    @State private var isLoading = false
    @State private var pathInput: String = ""
    @State private var showSettings = false

    private var isConnected: Bool {
        relayConnection.state == .connected
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if !isConnected {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                        Text(relayConnection.state.label)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    // Path input bar
                    HStack(spacing: 8) {
                        TextField("Path", text: $pathInput)
                            .font(.system(size: 14, design: .monospaced))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .onSubmit {
                                navigateTo(pathInput)
                            }

                        Button {
                            navigateTo(pathInput)
                        } label: {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                    if isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else {
                        List {
                            // Parent directory
                            if currentPath != "/" {
                                Button {
                                    let parent = (currentPath as NSString).deletingLastPathComponent
                                    navigateTo(parent)
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: "arrow.up.doc")
                                            .foregroundColor(.secondary)
                                            .frame(width: 24)
                                        Text("..")
                                            .foregroundColor(.primary)
                                    }
                                }
                            }

                            ForEach(entries.filter(\.isDir)) { entry in
                                Button {
                                    let newPath = currentPath == "/"
                                        ? "/\(entry.name)"
                                        : "\(currentPath)/\(entry.name)"
                                    navigateTo(newPath)
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: "folder.fill")
                                            .foregroundColor(.accentColor)
                                            .frame(width: 24)
                                        Text(entry.name)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                    }

                    // Open button at bottom
                    Button {
                        launchInCurrentPath()
                    } label: {
                        Text("Open in \(currentPathName)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(currentPath.isEmpty ? Color.gray : Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(currentPath.isEmpty)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }
            .navigationTitle("Select Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(relayConnection: relayConnection)
        }
        .onAppear {
            setupCallbacks()
            if isConnected {
                requestInitialListing()
            }
        }
        .onChange(of: relayConnection.state) { _, newState in
            if newState == .connected {
                requestInitialListing()
            }
        }
        .onDisappear {
            relayConnection.onDirListing = nil
            relayConnection.onLaunchResult = nil
        }
    }

    private var currentPathName: String {
        if currentPath.isEmpty { return "..." }
        return (currentPath as NSString).lastPathComponent
    }

    private func setupCallbacks() {
        relayConnection.onDirListing = { path, dirEntries in
            DispatchQueue.main.async {
                self.currentPath = path
                self.pathInput = path
                self.entries = dirEntries
                self.isLoading = false
            }
        }
    }

    private func requestInitialListing() {
        navigateTo("")
    }

    private func navigateTo(_ path: String) {
        isLoading = true
        relayConnection.sendControl(.listDir(path: path))
    }

    private func launchInCurrentPath() {
        let size = DisplayConfig.load().terminalSize()
        relayConnection.sendControl(.launch(cwd: currentPath, cols: size.cols, rows: size.rows))
    }
}
