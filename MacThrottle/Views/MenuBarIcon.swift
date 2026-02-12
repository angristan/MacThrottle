import SwiftUI

struct MenuBarIcon: View {
    let pressure: ThermalPressure
    let temperature: Double?
    let showTemperature: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .symbolRenderingMode(.palette)
                .foregroundStyle(pressure.color, .primary)
            if showTemperature, let temp = temperature {
                Text("\(Int(temp.rounded()))°")
                    .monospacedDigit()
                    .frame(minWidth: 30)
            }
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
}

#Preview {
    MenuBarIcon(pressure: .nominal, temperature: 101.0, showTemperature: true)
    MenuBarIcon(pressure: .nominal, temperature: 99.0, showTemperature: true)
}
