import SwiftUI
import AppKit

// AppDelegate to ensure proper activation on macOS 15.2+
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure app is active and menu bar is visible
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct MacThrottleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var monitor = ThermalMonitor()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(monitor: monitor)
        } label: {
            MenuBarIcon(pressure: monitor.pressure)
        }
        .menuBarExtraStyle(.window)

        Window("About MacThrottle", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}
