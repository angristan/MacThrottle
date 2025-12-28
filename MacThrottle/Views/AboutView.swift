import SwiftUI

struct AboutView: View {
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
        .frame(width: 300)
    }
}
