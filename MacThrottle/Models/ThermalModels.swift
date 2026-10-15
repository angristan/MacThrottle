import Foundation
import SwiftUI

enum ThermalPressure: String, Codable {
    case nominal
    case moderate
    case heavy
    case critical
    case unknown

    var displayName: String {
        switch self {
        case .nominal: return "Nominal"
        case .moderate: return "Moderate"
        case .heavy: return "Heavy"
        case .critical: return "Critical"
        case .unknown: return "Unknown"
        }
    }

    var isThrottling: Bool {
        switch self {
        case .heavy, .critical:
            return true
        default:
            return false
        }
    }

    var color: Color {
        switch self {
        case .nominal: return .green
        case .moderate: return .yellow
        case .heavy: return .orange
        case .critical: return .red
        case .unknown: return .gray
        }
    }
}

struct HistoryEntry {
    let pressure: ThermalPressure
    let temperature: Double?
    let fanSpeed: Double?  // Percentage 0-100%
    let timestamp: Date
}

enum TemperatureUnit: String, CaseIterable, Identifiable {
    case system
    case celsius
    case fahrenheit

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        }
    }

    /// Resolves `.system` using the macOS Temperature setting, falling back to the region.
    var resolved: TemperatureUnit {
        guard self == .system else { return self }
        switch UserDefaults.standard.string(forKey: "AppleTemperatureUnit") {
        case "Fahrenheit": return .fahrenheit
        case "Celsius": return .celsius
        default: return Locale.current.measurementSystem == .us ? .fahrenheit : .celsius
        }
    }

    var symbol: String {
        resolved == .fahrenheit ? "°F" : "°C"
    }

    /// Converts a temperature in Celsius to this unit.
    func convert(_ celsius: Double) -> Double {
        resolved == .fahrenheit ? celsius * 9 / 5 + 32 : celsius
    }
}
