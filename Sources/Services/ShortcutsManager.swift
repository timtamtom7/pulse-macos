import AppIntents
import Foundation

// MARK: - App Shortcuts Provider

struct PulseShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetCPULoadIntent(),
            phrases: [
                "Get \(.applicationName) CPU load",
                "CPU usage in \(.applicationName)"
            ],
            shortTitle: "CPU Load",
            systemImageName: "cpu"
        )

        AppShortcut(
            intent: GetMemoryUsageIntent(),
            phrases: [
                "Get \(.applicationName) memory usage",
                "RAM usage in \(.applicationName)"
            ],
            shortTitle: "Memory Usage",
            systemImageName: "memorychip"
        )

        AppShortcut(
            intent: GetSystemStatsIntent(),
            phrases: [
                "Get \(.applicationName) stats",
                "System status in \(.applicationName)"
            ],
            shortTitle: "System Stats",
            systemImageName: "chart.bar"
        )
    }
}

// MARK: - Get CPU Load Intent

struct GetCPULoadIntent: AppIntent {
    static var title: LocalizedStringResource = "Get CPU Load"
    static var description = IntentDescription("Returns the current CPU load from Pulse")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let stats = await PulseState.shared.stats
        let total = stats.cpuUser + stats.cpuSystem
        let idle = stats.cpuIdle

        let userPct = String(format: "%.1f", stats.cpuUser)
        let systemPct = String(format: "%.1f", stats.cpuSystem)
        let idlePct = String(format: "%.1f", idle)

        return .result(dialog: "CPU: User \(userPct)%, System \(systemPct)%, Idle \(idlePct)%. Total usage: \(String(format: "%.1f", total))%")
    }
}

// MARK: - Get Memory Usage Intent

struct GetMemoryUsageIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Memory Usage"
    static var description = IntentDescription("Returns the current memory usage from Pulse")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let stats = await PulseState.shared.stats
        let usedGB = Double(stats.ramUsed) / 1_073_741_824.0
        let totalGB = Double(stats.ramTotal) / 1_073_741_824.0
        let usedPct = (Double(stats.ramUsed) / Double(stats.ramTotal)) * 100

        return .result(dialog: "Memory: \(String(format: "%.1f", usedGB))GB / \(String(format: "%.1f", totalGB))GB (\(String(format: "%.1f", usedPct))% used)")
    }
}

// MARK: - Get System Stats Intent

struct GetSystemStatsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get System Stats"
    static var description = IntentDescription("Returns a summary of all system stats from Pulse")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let stats = await PulseState.shared.stats
        let totalCPU = stats.cpuUser + stats.cpuSystem
        let usedRAMGB = Double(stats.ramUsed) / 1_073_741_824.0
        let totalRAMGB = Double(stats.ramTotal) / 1_073_741_824.0
        let ramPct = (Double(stats.ramUsed) / Double(stats.ramTotal)) * 100

        let cpuText = "CPU: \(String(format: "%.0f", totalCPU))%"
        let ramText = "RAM: \(String(format: "%.1f", usedRAMGB))/\(String(format: "%.1f", totalRAMGB))GB (\(String(format: "%.0f", ramPct))%)"
        let diskUsedGB = Double(stats.diskUsed) / 1_073_741_824.0 / 1024.0
        let diskTotalGB = Double(stats.diskTotal) / 1_073_741_824.0 / 1024.0
        let diskPct = (Double(stats.diskUsed) / Double(stats.diskTotal)) * 100
        let diskText = "Disk: \(String(format: "%.0f", diskUsedGB))/\(String(format: "%.0f", diskTotalGB))GB (\(String(format: "%.0f", diskPct))%)"

        return .result(dialog: "\(cpuText). \(ramText). \(diskText)")
    }
}
