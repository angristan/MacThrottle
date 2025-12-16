import Foundation
import SwiftUI
import UserNotifications

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

    var iconName: String {
        switch self {
        case .nominal: return "thermometer.low"
        case .moderate: return "thermometer.medium"
        case .heavy: return "thermometer.high"
        case .trapping, .sleeping: return "thermometer.sun.fill"
        case .unknown: return "thermometer"
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

@Observable
final class ThermalMonitor {
    private(set) var pressure: ThermalPressure = .unknown
    private(set) var daemonRunning: Bool = false
    private var timer: Timer?
    private var previousPressure: ThermalPressure = .unknown

    private let stateFilePath = "/tmp/mac-throttle-thermal-state"

    var notificationsEnabled: Bool = UserDefaults.standard.bool(forKey: "notificationsEnabled") {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }

    init() {
        requestNotificationPermission()
        startMonitoring()
    }

    deinit {
        timer?.invalidate()
    }

    private func startMonitoring() {
        // Initial read
        updateThermalState()

        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateThermalState()
        }
    }

    private func updateThermalState() {
        guard let data = FileManager.default.contents(atPath: stateFilePath),
              let state = try? JSONDecoder().decode(ThermalState.self, from: data) else {
            daemonRunning = false
            pressure = .unknown
            return
        }

        // Check if data is fresh (within last 15 seconds)
        let now = Int(Date().timeIntervalSince1970)
        daemonRunning = (now - state.timestamp) < 15

        let newPressure = state.thermalPressure

        if newPressure != previousPressure {
            if notificationsEnabled && newPressure.isThrottling && !previousPressure.isThrottling {
                sendThrottleNotification(pressure: newPressure)
            }
            previousPressure = newPressure
        }

        pressure = newPressure
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendThrottleNotification(pressure: ThermalPressure) {
        let content = UNMutableNotificationContent()
        content.title = "Thermal Throttling"
        content.body = pressure == .trapping || pressure == .sleeping
            ? "Your Mac is severely throttled!"
            : "Your Mac is being throttled (Heavy pressure)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
