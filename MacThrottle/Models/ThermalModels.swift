import Foundation
import SwiftUI

enum ThermalPressure: String, Codable {
    case nominal
    case moderate
    case heavy
    case trapping
    case sleeping
    case unknown

    var displayName: String {
        switch self {
        case .nominal: return "Nominal"
        case .moderate: return "Moderate"
        case .heavy: return "Heavy"
        case .trapping: return "Trapping"
        case .sleeping: return "Sleeping"
        case .unknown: return "Unknown"
        }
    }

    var isThrottling: Bool {
        switch self {
        case .heavy, .trapping, .sleeping:
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
        case .trapping, .sleeping: return .red
        case .unknown: return .gray
        }
    }
}

struct ThermalState: Codable {
    let pressure: String
    let timestamp: Int

    var thermalPressure: ThermalPressure {
        ThermalPressure(rawValue: pressure) ?? .unknown
    }
}

struct HistoryEntry {
    let pressure: ThermalPressure
    let temperature: Double?
    let timestamp: Date
}
