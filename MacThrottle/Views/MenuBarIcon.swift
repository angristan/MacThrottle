import SwiftUI

struct MenuBarIcon: View {
    let pressure: ThermalPressure
    let temperature: Double?
    let showTemperature: Bool

    var body: some View {
        Image(systemName: iconName)
            .symbolRenderingMode(.palette)
            .foregroundStyle(pressure.color, .primary)
            .onAppear {
                getStatusItems()?.first?.button?.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
            }
        if showTemperature, let temp = temperature {
            Text("\(Int(temp.rounded()))°")
        }
    }

    private var iconName: String {
        switch pressure {
        case .nominal: return "thermometer.low"
        case .moderate: return "thermometer.medium"
        case .heavy: return "thermometer.high"
        case .critical: return "thermometer.sun.fill"
        case .unknown: return "thermometer.variable.and.figure"
        }
    }

    private func getStatusItems() -> [NSStatusItem]? {
        let statusBar = NSStatusBar.system

        guard
            statusBar.responds(to: NSSelectorFromString("_statusItems")),
            let statusItemsPointer = statusBar.value(forKey: "_statusItems") as? NSPointerArray,
            let statusItems = statusItemsPointer.allObjects as? [NSStatusItem]
        else { return nil }

        return statusItems
    }
}
