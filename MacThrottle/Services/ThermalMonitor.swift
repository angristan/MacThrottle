import Foundation
import SwiftUI
import UserNotifications

@Observable
final class ThermalMonitor {
    private(set) var pressure: ThermalPressure = .unknown
    private(set) var temperature: Double?
    private(set) var history: [HistoryEntry] = []
    private var timer: Timer?
    private var previousPressure: ThermalPressure = .unknown

    private let historyDuration: TimeInterval = 600 // 10 minutes

    // Notification settings
    var notifyOnHeavy: Bool = UserDefaults.standard.object(forKey: "notifyOnHeavy") as? Bool ?? true {
        didSet { UserDefaults.standard.set(notifyOnHeavy, forKey: "notifyOnHeavy") }
    }

    var notifyOnCritical: Bool = UserDefaults.standard.object(forKey: "notifyOnCritical") as? Bool ?? true {
        didSet { UserDefaults.standard.set(notifyOnCritical, forKey: "notifyOnCritical") }
    }

    var notifyOnRecovery: Bool = UserDefaults.standard.object(forKey: "notifyOnRecovery") as? Bool ?? false {
        didSet { UserDefaults.standard.set(notifyOnRecovery, forKey: "notifyOnRecovery") }
    }

    var notificationSound: Bool = UserDefaults.standard.object(forKey: "notificationSound") as? Bool ?? false {
        didSet { UserDefaults.standard.set(notificationSound, forKey: "notificationSound") }
    }

    var timeInEachState: [(pressure: ThermalPressure, duration: TimeInterval)] {
        guard history.count >= 2 else { return [] }

        var durations: [ThermalPressure: TimeInterval] = [:]

        for i in 0..<(history.count - 1) {
            let current = history[i]
            let next = history[i + 1]
            let duration = next.timestamp.timeIntervalSince(current.timestamp)
            durations[current.pressure, default: 0] += duration
        }

        // Add time for the current (last) state up to now
        if let last = history.last {
            let duration = Date().timeIntervalSince(last.timestamp)
            durations[last.pressure, default: 0] += duration
        }

        // Sort by duration descending
        return durations.map { (pressure: $0.key, duration: $0.value) }
            .sorted { $0.duration > $1.duration }
    }

    var totalHistoryDuration: TimeInterval {
        guard let first = history.first else { return 0 }
        return Date().timeIntervalSince(first.timestamp)
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
        let newPressure = ThermalPressureReader.shared.readPressure() ?? .unknown

        if newPressure != previousPressure {
            // Check for throttling notifications
            if shouldNotify(for: newPressure, previous: previousPressure) {
                sendThrottleNotification(pressure: newPressure)
            }

            // Check for recovery notification
            let recovered = previousPressure.isThrottling && !newPressure.isThrottling
            if notifyOnRecovery && recovered && newPressure != .unknown {
                sendRecoveryNotification()
            }

            previousPressure = newPressure
        }

        pressure = newPressure

        // Read CPU temperature (SMC primary, HID fallback)
        temperature = SMCReader.shared.readCPUTemperature()
            ?? HIDTemperatureReader.shared.readCPUTemperature()

        // Record history
        let entry = HistoryEntry(pressure: newPressure, temperature: temperature, timestamp: Date())
        history.append(entry)

        // Trim old entries
        let cutoff = Date().addingTimeInterval(-historyDuration)
        history.removeAll { $0.timestamp < cutoff }
    }

    private func shouldNotify(for pressure: ThermalPressure, previous: ThermalPressure) -> Bool {
        switch pressure {
        case .heavy:
            return notifyOnHeavy && !previous.isThrottling
        case .critical:
            return notifyOnCritical && previous != .critical
        default:
            return false
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendThrottleNotification(pressure: ThermalPressure) {
        let content = UNMutableNotificationContent()
        content.title = "Thermal Throttling"
        content.body = pressure == .critical
            ? "Your Mac is severely throttled!"
            : "Your Mac is being throttled (Heavy pressure)"
        if notificationSound {
            content.sound = .default
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func sendRecoveryNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Thermal Pressure Recovered"
        content.body = "Your Mac is no longer being throttled"
        if notificationSound {
            content.sound = .default
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
