import Foundation

/// Reads thermal pressure level directly from the system using Darwin notifications.
/// This provides the same 5-level granularity as `powermetrics -s thermal` without
/// requiring root privileges or a helper daemon.
final class ThermalPressureReader {
    static let shared = ThermalPressureReader()

    private var token: Int32 = 0
    private var isRegistered = false

    private init() {
        register()
    }

    deinit {
        if isRegistered {
            _ = notify_cancel(token)
        }
    }

    private func register() {
        let result = notify_register_check("com.apple.system.thermalpressurelevel", &token)
        isRegistered = (result == notifyStatusOK)
    }

    /// Reads the current thermal pressure level.
    /// Returns nil if the notification system is unavailable.
    func readPressure() -> ThermalPressure? {
        guard isRegistered else { return nil }

        var state: UInt64 = 0
        let result = notify_get_state(token, &state)

        guard result == notifyStatusOK else { return nil }

        switch state {
        case 0: return .nominal
        case 1: return .moderate
        case 2: return .heavy
        case 3, 4: return .critical
        default: return .unknown
        }
    }
}

// MARK: - Darwin notify functions

@_silgen_name("notify_register_check")
private func notify_register_check(
    _ name: UnsafePointer<CChar>,
    _ token: UnsafeMutablePointer<Int32>
) -> UInt32

@_silgen_name("notify_get_state")
private func notify_get_state(
    _ token: Int32,
    _ state: UnsafeMutablePointer<UInt64>
) -> UInt32

@_silgen_name("notify_cancel")
private func notify_cancel(_ token: Int32) -> UInt32

private let notifyStatusOK: UInt32 = 0
