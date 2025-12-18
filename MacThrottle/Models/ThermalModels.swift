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
    let timestamp: Date
}
