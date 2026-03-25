import Foundation

struct AlertRule: Identifiable, Codable {
    let id: UUID
    var metric: AlertMetric
    var threshold: Double
    var condition: AlertCondition
    var isEnabled: Bool
    var lastTriggered: Date?

    init(
        id: UUID = UUID(),
        metric: AlertMetric,
        threshold: Double,
        condition: AlertCondition,
        isEnabled: Bool = true,
        lastTriggered: Date? = nil
    ) {
        self.id = id
        self.metric = metric
        self.threshold = threshold
        self.condition = condition
        self.isEnabled = isEnabled
        self.lastTriggered = lastTriggered
    }
}

enum AlertMetric: String, Codable, CaseIterable {
    case cpuUsage = "CPU Usage"
    case memoryUsage = "Memory Usage"
    case diskUsage = "Disk Usage"
    case networkBandwidthIn = "Download Speed"
    case networkBandwidthOut = "Upload Speed"
}

enum AlertCondition: String, Codable, CaseIterable {
    case above = "Above"
    case below = "Below"
}

final class AlertManager {
    static let shared = AlertManager()

    private let rulesKey = "alertRules"
    private var rules: [AlertRule] = []
    private var onAlertTriggered: ((AlertRule, Double) -> Void)?

    private init() {
        loadRules()
    }

    func setAlertCallback(_ callback: @escaping (AlertRule, Double) -> Void) {
        onAlertTriggered = callback
    }

    func loadRules() {
        guard let data = UserDefaults.standard.data(forKey: rulesKey) else {
            rules = []
            return
        }
        do {
            rules = try JSONDecoder().decode([AlertRule].self, from: data)
        } catch {
            rules = []
        }
    }

    func getRules() -> [AlertRule] {
        return rules
    }

    func saveRule(_ rule: AlertRule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
        } else {
            rules.append(rule)
        }
        saveRules()
    }

    func deleteRule(_ id: UUID) {
        rules.removeAll { $0.id == id }
        saveRules()
    }

    func checkAlerts(stats: SystemStats) {
        for rule in rules where rule.isEnabled {
            let currentValue = getCurrentValue(for: rule.metric, stats: stats)
            let shouldTrigger = checkCondition(rule.condition, current: currentValue, threshold: rule.threshold)

            if shouldTrigger {
                // Don't alert if we alerted in the last 5 minutes
                if let last = rule.lastTriggered, Date().timeIntervalSince(last) < 300 {
                    continue
                }

                var updatedRule = rule
                updatedRule.lastTriggered = Date()
                saveRule(updatedRule)
                onAlertTriggered?(updatedRule, currentValue)
            }
        }
    }

    private func getCurrentValue(for metric: AlertMetric, stats: SystemStats) -> Double {
        switch metric {
        case .cpuUsage:
            return stats.cpuTotal
        case .memoryUsage:
            return stats.ramPercentage
        case .diskUsage:
            return stats.diskPercentage
        case .networkBandwidthIn:
            return stats.bandwidthIn
        case .networkBandwidthOut:
            return stats.bandwidthOut
        }
    }

    private func checkCondition(_ condition: AlertCondition, current: Double, threshold: Double) -> Bool {
        switch condition {
        case .above:
            return current > threshold
        case .below:
            return current < threshold
        }
    }

    private func saveRules() {
        do {
            let data = try JSONEncoder().encode(rules)
            UserDefaults.standard.set(data, forKey: rulesKey)
        } catch {
            print("Failed to save alert rules: \(error)")
        }
    }
}
