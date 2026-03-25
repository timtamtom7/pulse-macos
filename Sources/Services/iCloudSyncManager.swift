import Foundation

final class PulseSyncManager: ObservableObject {
    static let shared = PulseSyncManager()

    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSynced: Date?

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case synced
        case offline
        case error(String)
    }

    private let store = NSUbiquitousKeyValueStore.default
    private var observers: [NSObjectProtocol] = []

    private init() {
        setupObservers()
    }

    private func setupObservers() {
        let notification = NSUbiquitousKeyValueStore.didChangeExternallyNotification
        let observer = NotificationCenter.default.addObserver(
            forName: notification,
            object: store,
            queue: .main
        ) { [weak self] _ in
            self?.handleExternalChange()
        }
        observers.append(observer)
    }

    // MARK: - Sync

    struct SyncPayload: Codable {
        var settings: PulseSettings
        var thresholds: AlertThresholds
        var lastExportDate: Date?

        struct PulseSettings: Codable {
            var refreshInterval: Int
            var showCpuTemp: Bool
            var showNetworkSpeed: Bool
            var historyHours: Int
        }

        struct AlertThresholds: Codable {
            var cpuWarn: Double
            var cpuCritical: Double
            var ramWarn: Double
            var ramCritical: Double
        }
    }

    func sync() {
        guard isICloudAvailable else {
            syncStatus = .offline
            return
        }

        syncStatus = .syncing

        do {
            let payload = buildPayload()
            let data = try JSONEncoder().encode(payload)
            store.set(data, forKey: "pulse.sync.data")
            store.synchronize()

            syncStatus = .synced
            lastSynced = Date()
        } catch {
            syncStatus = .error(error.localizedDescription)
        }
    }

    func pullFromCloud() {
        guard isICloudAvailable else { return }

        guard let data = store.data(forKey: "pulse.sync.data"),
              let payload = try? JSONDecoder().decode(SyncPayload.self, from: data) else {
            return
        }

        applyPayload(payload)
    }

    private func buildPayload() -> SyncPayload {
        let settings = SyncPayload.PulseSettings(
            refreshInterval: UserDefaults.standard.integer(forKey: "pulse_refreshInterval"),
            showCpuTemp: UserDefaults.standard.bool(forKey: "pulse_showCpuTemp"),
            showNetworkSpeed: UserDefaults.standard.bool(forKey: "pulse_showNetworkSpeed"),
            historyHours: UserDefaults.standard.integer(forKey: "pulse_historyHours")
        )

        let thresholds = SyncPayload.AlertThresholds(
            cpuWarn: UserDefaults.standard.double(forKey: "pulse_cpuWarn"),
            cpuCritical: UserDefaults.standard.double(forKey: "pulse_cpuCritical"),
            ramWarn: UserDefaults.standard.double(forKey: "pulse_ramWarn"),
            ramCritical: UserDefaults.standard.double(forKey: "pulse_ramCritical")
        )

        return SyncPayload(
            settings: settings,
            thresholds: thresholds,
            lastExportDate: nil
        )
    }

    private func applyPayload(_ payload: SyncPayload) {
        UserDefaults.standard.set(payload.settings.refreshInterval, forKey: "pulse_refreshInterval")
        UserDefaults.standard.set(payload.settings.showCpuTemp, forKey: "pulse_showCpuTemp")
        UserDefaults.standard.set(payload.settings.showNetworkSpeed, forKey: "pulse_showNetworkSpeed")
        UserDefaults.standard.set(payload.settings.historyHours, forKey: "pulse_historyHours")
        UserDefaults.standard.set(payload.thresholds.cpuWarn, forKey: "pulse_cpuWarn")
        UserDefaults.standard.set(payload.thresholds.cpuCritical, forKey: "pulse_cpuCritical")
        UserDefaults.standard.set(payload.thresholds.ramWarn, forKey: "pulse_ramWarn")
        UserDefaults.standard.set(payload.thresholds.ramCritical, forKey: "pulse_ramCritical")
    }

    private func handleExternalChange() {
        pullFromCloud()
        syncStatus = .synced
        lastSynced = Date()
    }

    var isICloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    func syncNow() {
        sync()
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
}
