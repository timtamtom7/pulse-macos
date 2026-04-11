import Foundation
import UserNotifications

final class AlertNotificationService {
    static let shared = AlertNotificationService()

    private var lastCPUNotification: Date?
    private var lastRAMNotification: Date?

    static let defaultCPUWarningThreshold: Double = 80.0
    static let defaultCPUCriticalThreshold: Double = 95.0
    static let defaultRAMWarningThreshold: Double = 80.0
    static let defaultRAMCriticalThreshold: Double = 95.0
    static let notificationCooldownInterval: TimeInterval = 300

    private init() {}

    var cooldownInterval: TimeInterval {
        Self.notificationCooldownInterval
    }

    // MARK: - Thresholds

    var cpuWarnThreshold: Double {
        get { UserDefaults.standard.double(forKey: "pulse_cpuWarn").nonZeroOr(Self.defaultCPUWarningThreshold) }
        set { UserDefaults.standard.set(newValue, forKey: "pulse_cpuWarn") }
    }

    var cpuCriticalThreshold: Double {
        get { UserDefaults.standard.double(forKey: "pulse_cpuCritical").nonZeroOr(Self.defaultCPUCriticalThreshold) }
        set { UserDefaults.standard.set(newValue, forKey: "pulse_cpuCritical") }
    }

    var ramWarnThreshold: Double {
        get { UserDefaults.standard.double(forKey: "pulse_ramWarn").nonZeroOr(Self.defaultRAMWarningThreshold) }
        set { UserDefaults.standard.set(newValue, forKey: "pulse_ramWarn") }
    }

    var ramCriticalThreshold: Double {
        get { UserDefaults.standard.double(forKey: "pulse_ramCritical").nonZeroOr(Self.defaultRAMCriticalThreshold) }
        set { UserDefaults.standard.set(newValue, forKey: "pulse_ramCritical") }
    }

    // MARK: - Check Stats

    func checkStats(_ stats: SystemStats) {
        checkCPU(stats)
        checkRAM(stats)
    }

    private func checkCPU(_ stats: SystemStats) {
        let totalCPU = stats.cpuUser + stats.cpuSystem

        if totalCPU >= cpuCriticalThreshold && canSendCPUNotification() {
            sendCPUCriticalNotification(usage: totalCPU)
            lastCPUNotification = Date()
        } else if totalCPU >= cpuWarnThreshold && canSendCPUNotification() {
            sendCPUWarningNotification(usage: totalCPU)
            lastCPUNotification = Date()
        }
    }

    private func checkRAM(_ stats: SystemStats) {
        let ramPct = (Double(stats.ramUsed) / Double(stats.ramTotal)) * 100

        if ramPct >= ramCriticalThreshold && canSendRAMNotification() {
            sendRAMCriticalNotification(usage: ramPct)
            lastRAMNotification = Date()
        } else if ramPct >= ramWarnThreshold && canSendRAMNotification() {
            sendRAMWarningNotification(usage: ramPct)
            lastRAMNotification = Date()
        }
    }

    // MARK: - Cooldown

    private func canSendCPUNotification() -> Bool {
        guard let last = lastCPUNotification else { return true }
        return Date().timeIntervalSince(last) > cooldownInterval
    }

    private func canSendRAMNotification() -> Bool {
        guard let last = lastRAMNotification else { return true }
        return Date().timeIntervalSince(last) > cooldownInterval
    }

    // MARK: - Notifications

    private func sendCPUWarningNotification(usage: Double) {
        sendNotification(
            title: "Pulse: CPU Usage High",
            body: "CPU usage at \(String(format: "%.0f", usage))%. Consider closing some apps.",
            identifier: "cpu-warn"
        )
    }

    private func sendCPUCriticalNotification(usage: Double) {
        sendNotification(
            title: "Pulse: CPU Critical",
            body: "CPU usage at \(String(format: "%.0f", usage))%! Your Mac may be overloaded.",
            identifier: "cpu-critical"
        )
    }

    private func sendRAMWarningNotification(usage: Double) {
        sendNotification(
            title: "Pulse: Memory Usage High",
            body: "Memory at \(String(format: "%.0f", usage))%. Consider freeing up RAM.",
            identifier: "ram-warn"
        )
    }

    private func sendRAMCriticalNotification(usage: Double) {
        sendNotification(
            title: "Pulse: Memory Critical",
            body: "Memory at \(String(format: "%.0f", usage))%! Your Mac may be running out of RAM.",
            identifier: "ram-critical"
        )
    }

    private func sendNotification(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default // Respects macOS notification sound settings
        content.categoryIdentifier = "PULSE_ALERT"

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification auth error: \(error)")
            }
        }
        // Register notification categories for actionable notifications
        let openAction = UNNotificationAction(identifier: "OPEN_PULSE", title: "Open Pulse", options: .foreground)
        let dismissAction = UNNotificationAction(identifier: "DISMISS", title: "Dismiss", options: .destructive)
        let alertCategory = UNNotificationCategory(identifier: "PULSE_ALERT", actions: [openAction, dismissAction], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([alertCategory])
    }
}

private extension Double {
    func nonZeroOr(_ defaultValue: Double) -> Double {
        self == 0 ? defaultValue : self
    }
}
