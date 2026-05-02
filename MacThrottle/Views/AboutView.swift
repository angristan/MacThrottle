import SwiftUI

struct AboutView: View {
    @State private var updateChecker = UpdateChecker()

    var body: some View {
        VStack(spacing: 16) {
            if #available(macOS 26.0, *) {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 128, height: 128)
                    .cornerRadius(24)
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 24))
            } else {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 128, height: 128)
                    .cornerRadius(24)
            }

            Text("MacThrottle")
                .font(.title)
                .fontWeight(.bold)

            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Monitor your Mac's thermal pressure\nand get notified when throttling occurs.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            updateSection

            if let url = URL(string: "https://github.com/angristan/MacThrottle") {
                if #available(macOS 26.0, *) {
                    Link("View on GitHub", destination: url)
                        .font(.caption)
                        .glassEffect()
                } else {
                    Link("View on GitHub", destination: url)
                        .font(.caption)
                }
            }
        }
        .padding(32)
        .frame(width: 320)
    }

    @ViewBuilder
    private var updateSection: some View {
        VStack(spacing: 8) {
            Button {
                Task {
                    await updateChecker.checkForUpdates()
                }
            } label: {
                if updateChecker.isChecking {
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Checking...")
                    }
                } else {
                    Label("Check for Updates", systemImage: "arrow.clockwise")
                }
            }
            .disabled(updateChecker.isChecking)
            .controlSize(.small)
            .frame(minWidth: 150)

            updateStatus
        }
    }

    @ViewBuilder
    private var updateStatus: some View {
        switch updateChecker.status {
        case .idle:
            EmptyView()
        case .checking:
            Text("Checking for the latest release...")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .updateAvailable(let update):
            VStack(spacing: 6) {
                Text("Version \(update.version) is available.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Link(destination: update.releaseURL) {
                    Label("Open Release", systemImage: "arrow.up.forward.square")
                }
                .font(.caption)
            }
        case .upToDate:
            Text("You're up to date.")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .failed(let message):
            Text("Update check failed: \(message)")
                .font(.caption)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
        }
    }
}
