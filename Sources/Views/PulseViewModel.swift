import Foundation
import Combine

final class PulseViewModel: ObservableObject {
    @Published var stats = SystemStats.zero
    @Published var samples: [Sample] = []
    @Published var hourlySamples: [HourlySample] = []
    @Published var topProcesses: [AppProcessInfo] = []
    @Published var selectedTab = 0
    @Published var historyHours: Int = 24

    private var sampleTimer: Timer?
    private var processTimer: Timer?

    init() {
        setupStatsListener()
        startSampleRecording()
        startProcessMonitoring()
        loadHistory()
    }

    private func setupStatsListener() {
        SystemMonitor.shared.onStatsUpdate = { [weak self] newStats in
            DispatchQueue.main.async {
                self?.stats = newStats
            }
        }
    }

    private func startSampleRecording() {
        sampleTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            SettingsStore.shared.recordSample(self.stats)
            self.loadHistory()
        }
    }

    private func startProcessMonitoring() {
        processTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshProcesses()
            }
        }
    }

    func refreshProcesses() {
        topProcesses = ProcessMonitor.shared.getTopProcesses(limit: 10)
    }

    func loadHistory() {
        let recent = SettingsStore.shared.getRecentSamples(hours: historyHours)
        samples = recent
        hourlySamples = aggregateHourly(samples: recent)
    }

    private func aggregateHourly(samples: [Sample]) -> [HourlySample] {
        let calendar = Calendar.current
        var hourly: [Int: [Sample]] = [:]

        for sample in samples {
            let hour = calendar.component(.hour, from: sample.timestamp)
            hourly[hour, default: []].append(sample)
        }

        return hourly.keys.sorted().compactMap { hour in
            guard let samples = hourly[hour], !samples.isEmpty else { return nil }
            let avgCpuUser = samples.map(\.cpuUser).reduce(0, +) / Double(samples.count)
            let avgCpuSystem = samples.map(\.cpuSystem).reduce(0, +) / Double(samples.count)
            let avgRamUsed = samples.map(\.ramUsed).reduce(0, +) / Double(samples.count)
            let peakCpu = samples.map(\.cpuTotal).max() ?? 0
            let avgNetIn = samples.map(\.networkInDelta).reduce(0, +) / Double(samples.count)
            let avgNetOut = samples.map(\.networkOutDelta).reduce(0, +) / Double(samples.count)
            let date = samples.first?.timestamp ?? Date()

            return HourlySample(
                hour: hour,
                date: date,
                avgCpuUser: avgCpuUser,
                avgCpuSystem: avgCpuSystem,
                avgRamUsed: avgRamUsed,
                peakCpu: peakCpu,
                avgNetworkIn: avgNetIn,
                avgNetworkOut: avgNetOut
            )
        }
    }

    // MARK: - Export

    func exportCSV() -> URL? {
        var csv = "Timestamp,CPU User,CPU System,CPU Idle,RAM Used (bytes),RAM Total (bytes),Disk Used (bytes),Disk Total (bytes),Network In (B/s),Network Out (B/s)\n"
        let formatter = ISO8601DateFormatter()

        for sample in samples {
            let line = "\(formatter.string(from: sample.timestamp)),\(sample.cpuUser),\(sample.cpuSystem),\(sample.cpuIdle),\(Int(sample.ramUsed)),\(Int(sample.ramTotal)),\(Int(sample.diskUsed)),\(Int(sample.diskTotal)),\(Int(sample.networkInDelta)),\(Int(sample.networkOutDelta))"
            csv += line + "\n"
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("pulse_export.csv")
        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }

    deinit {
        sampleTimer?.invalidate()
        processTimer?.invalidate()
    }
}
