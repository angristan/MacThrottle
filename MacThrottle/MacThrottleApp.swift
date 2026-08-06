import SwiftUI

@main
struct MacThrottleApp: App {
    @State private var isMenuVisible = false
    @State private var monitor = ThermalMonitor()

    var body: some Scene {
        MenuBarExtra {
            ZStack {
                Color.clear
                    .frame(width: 0, height: 0)
                    .onAppear { isMenuVisible = true }
                    .onDisappear { isMenuVisible = false }
                if isMenuVisible {
                    MenuContentView(monitor: monitor)
                }
            }
        } label: {
            MenuBarIcon(
                pressure: monitor.pressure,
                temperature: monitor.showTemperatureInMenuBar ? monitor.temperature : nil,
                showTemperature: monitor.showTemperatureInMenuBar
            )
        }
        .menuBarExtraStyle(.window)

        Window("About MacThrottle", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}
