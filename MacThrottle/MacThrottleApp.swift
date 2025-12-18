import SwiftUI

@main
struct MacThrottleApp: App {
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
