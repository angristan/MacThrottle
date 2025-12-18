import SwiftUI

struct MenuBarIcon: View {
    let pressure: ThermalPressure

    var body: some View {
        Image(systemName: iconName)
            .symbolRenderingMode(.palette)
            .foregroundStyle(pressure.color, .primary)
    }

    private var iconName: String {
        switch pressure {
        case .nominal: return "thermometer.low"
        case .moderate: return "thermometer.medium"
        case .heavy: return "thermometer.high"
        case .trapping, .sleeping: return "thermometer.sun.fill"
        case .unknown: return "thermometer.variable.and.figure"
        }
    }
}
