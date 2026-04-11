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

        AppShortcut(
            intent: GetDiskUsageIntent(),
            phrases: [
                "Get \(.applicationName) disk usage",
                "Check disk space in \(.applicationName)"
            ],
            shortTitle: "Disk Usage",
            systemImageName: "externaldrive"
        )

        AppShortcut(
            intent: GetNetworkStatsIntent(),
            phrases: [
                "Get \(.applicationName) network speed",
                "Check network activity in \(.applicationName)"
            ],
            shortTitle: "Network Stats",
            systemImageName: "network"
        )
    }
}

// MARK: - Get CPU Load Intent

struct GetCPULoadIntent: AppIntent {
    static var title: LocalizedStringResource = "Get CPU Load"
    static var description = IntentDescription("Returns the current CPU load from Pulse")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let stats = PulseState.shared.stats
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

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let stats = PulseState.shared.stats
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

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let stats = PulseState.shared.stats
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

// MARK: - Get Disk Usage Intent

struct GetDiskUsageIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Disk Usage"
    static var description = IntentDescription("Returns the current disk usage from Pulse")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let stats = PulseState.shared.stats
        let usedGB = Double(stats.diskUsed) / 1_073_741_824.0 / 1024.0
        let totalGB = Double(stats.diskTotal) / 1_073_741_824.0 / 1024.0
        let usedPct = (Double(stats.diskUsed) / Double(stats.diskTotal)) * 100
        let freeGB = totalGB - usedGB

        return .result(dialog: "Disk: \(String(format: "%.0f", usedGB))GB used of \(String(format: "%.0f", totalGB))GB (\(String(format: "%.0f", usedPct))%). \(String(format: "%.0f", freeGB))GB free.")
    }
}

// MARK: - Get Network Stats Intent

struct GetNetworkStatsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Network Stats"
    static var description = IntentDescription("Returns the current network activity from Pulse")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let stats = PulseState.shared.stats
        let downloadSpeed = FormatUtils.formatSpeed(bytesPerSecond: stats.bandwidthIn)
        let uploadSpeed = FormatUtils.formatSpeed(bytesPerSecond: stats.bandwidthOut)

        return .result(dialog: "Network: Download \(downloadSpeed), Upload \(uploadSpeed)")
    }
}

// MARK: - Entity for Spotlight Integration

struct PulseSystemStatsEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "System Stats")
    static var defaultQuery = PulseStatsQuery()

    var id: String
    var cpuUsage: Double
    var memoryUsage: Double
    var diskUsage: Double

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(Int(cpuUsage))% CPU, \(Int(memoryUsage))% RAM",
            subtitle: "\(Int(diskUsage))% Disk used"
        )
    }

    @MainActor
    static func current() -> PulseSystemStatsEntity {
        let stats = PulseState.shared.stats
        return PulseSystemStatsEntity(
            id: "current",
            cpuUsage: stats.cpuUser + stats.cpuSystem,
            memoryUsage: (Double(stats.ramUsed) / Double(stats.ramTotal)) * 100,
            diskUsage: (Double(stats.diskUsed) / Double(stats.diskTotal)) * 100
        )
    }
}

struct PulseStatsQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [PulseSystemStatsEntity] {
        var results: [PulseSystemStatsEntity] = []
        for id in identifiers {
            if id == "current" {
                let entity = await PulseSystemStatsEntity.current()
                results.append(entity)
            }
        }
        return results
    }

    func suggestedEntities() async throws -> [PulseSystemStatsEntity] {
        [await PulseSystemStatsEntity.current()]
    }
}
