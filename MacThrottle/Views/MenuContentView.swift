import SwiftUI

func colorForTemperature(_ temp: Double) -> Color {
    switch temp {
    case ..<60: return .green
    case 60..<80: return .yellow
    case 80..<95: return .orange
    default: return .red
    }
}

struct MenuContentView: View {
    @Bindable var monitor: ThermalMonitor
    @State private var statusMessage: String?
    @State private var isError: Bool = false
    @Environment(\.openWindow) private var openWindow

    private var helperNeedsUpdate: Bool {
        guard monitor.daemonRunning else { return false }
        return HelperInstaller.needsUpdate()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if monitor.daemonRunning {
                HStack {
                    Text("Thermal Pressure:")
                    Text(monitor.pressure.displayName)
                        .foregroundColor(monitor.pressure.color)
                        .fontWeight(.semibold)
                    Spacer()
                    if let temp = monitor.temperature {
                        Text("\(Int(temp.rounded()))°C")
                            .foregroundColor(colorForTemperature(temp))
                            .fontWeight(.semibold)
                    }
                }
                .font(.headline)

                if monitor.history.count >= 2 {
                    HistoryGraphView(history: monitor.history)
                }

                if !monitor.timeInEachState.isEmpty {
                    Divider()
                    Text("Statistics")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TimeBreakdownView(
                        timeInEachState: monitor.timeInEachState,
                        totalDuration: monitor.totalHistoryDuration
                    )
                }

                if helperNeedsUpdate {
                    Divider()
                    Text("Helper update available")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Button("Update Helper...") {
                        installHelper(update: true)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            } else {
                Text("Helper not installed or not running")
                    .font(.headline)
                Text("Required to monitor thermal pressure")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Install Helper...") {
                    installHelper(update: false)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            if let message = statusMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(isError ? .red : .green)
            }

            Divider()

            if monitor.daemonRunning {
                Text("Notifications")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Toggle("On Heavy", isOn: $monitor.notifyOnHeavy)
                Toggle("On Critical", isOn: $monitor.notifyOnCritical)
                Toggle("On Recovery", isOn: $monitor.notifyOnRecovery)
                Toggle("Sound", isOn: $monitor.notificationSound)

                Divider()

                Button("Uninstall Helper...") {
                    uninstallHelper()
                }
                .controlSize(.small)
            }

            Divider()

            HStack {
                Button("About") {
                    openAboutWindow()
                }
                .controlSize(.small)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
                .controlSize(.small)
            }
        }
        .padding(12)
        .frame(width: 260)
    }

    private func openAboutWindow() {
        openWindow(id: "about")
        NSApp.activate(ignoringOtherApps: true)
    }

    private func installHelper(update: Bool) {
        statusMessage = nil
        isError = false

        HelperInstaller.install(update: update) { result in
            switch result {
            case .success(let message):
                statusMessage = message
                isError = false
            case .failure(let error):
                statusMessage = error.localizedDescription
                isError = true
            }
        }
    }

    private func uninstallHelper() {
        statusMessage = nil
        isError = false

        HelperInstaller.uninstall { result in
            switch result {
            case .success(let message):
                statusMessage = message
                isError = false
            case .failure(let error):
                statusMessage = error.localizedDescription
                isError = true
            }
        }
    }
}
