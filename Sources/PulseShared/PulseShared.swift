import Foundation

public enum PulseConstants {
    public static let appGroupIdentifier = "group.com.pulse.macos"
    public static let widgetCPUKey = "widget_cpu"
    public static let widgetMemoryKey = "widget_memory"
    public static let widgetNetworkKey = "widget_network"
    public static let widgetMacNameKey = "widget_mac_name"

    public static let defaultCPULimit: Double = 80.0
    public static let defaultMemoryLimit: Double = 80.0
    public static let defaultDiskLimit: Double = 90.0

    public static let sampleIntervalSeconds: Double = 60
    public static let statsCollectionInterval: TimeInterval = 2.0
    public static let retentionDays = 7
}

public final class WidgetDataProvider {
    public static let shared = WidgetDataProvider()

    private let userDefaults: UserDefaults?
    private let useAppGroup: Bool

    private init() {
        // Try app group first; fall back to standard UserDefaults if unavailable
        if let groupDefaults = UserDefaults(suiteName: PulseConstants.appGroupIdentifier) {
            self.userDefaults = groupDefaults
            self.useAppGroup = true
        } else {
            self.userDefaults = .standard
            self.useAppGroup = false
        }
    }

    public func updateWidgetData(cpuPercent: Int, memoryPercent: Int, networkSpeed: String, macName: String) {
        userDefaults?.set(cpuPercent, forKey: PulseConstants.widgetCPUKey)
        userDefaults?.set(memoryPercent, forKey: PulseConstants.widgetMemoryKey)
        userDefaults?.set(networkSpeed, forKey: PulseConstants.widgetNetworkKey)
        userDefaults?.set(macName, forKey: PulseConstants.widgetMacNameKey)
    }

    public func getCPUPercent() -> Int {
        userDefaults?.integer(forKey: PulseConstants.widgetCPUKey) ?? 0
    }

    public func getMemoryPercent() -> Int {
        userDefaults?.integer(forKey: PulseConstants.widgetMemoryKey) ?? 0
    }

    public func getNetworkSpeed() -> String {
        userDefaults?.string(forKey: PulseConstants.widgetNetworkKey) ?? "0 MB/s"
    }

    public func getMacName() -> String {
        userDefaults?.string(forKey: PulseConstants.widgetMacNameKey) ?? "Mac"
    }
}
