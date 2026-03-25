import Foundation

struct ProcessHistoryEntry: Identifiable, Codable {
    let id: UUID
    let processName: String
    let pid: Int32
    let cpuUsage: Double
    let memoryUsage: UInt64
    let timestamp: Date
}

final class ProcessHistoryManager {
    static let shared = ProcessHistoryManager()

    private let historyKey = "processHistory"
    private let maxEntries = 1000

    private init() {}

    func recordTopProcesses(_ processes: [AppProcessInfo]) {
        var history = fetchHistory()

        for process in processes.prefix(5) {
            let entry = ProcessHistoryEntry(
                id: UUID(),
                processName: process.name,
                pid: process.id,
                cpuUsage: process.cpuUsage,
                memoryUsage: process.memoryUsage,
                timestamp: Date()
            )
            history.append(entry)
        }

        if history.count > maxEntries {
            history = Array(history.suffix(maxEntries))
        }

        saveHistory(history)
    }

    func fetchHistory() -> [ProcessHistoryEntry] {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return [] }
        do {
            return try JSONDecoder().decode([ProcessHistoryEntry].self, from: data)
        } catch {
            return []
        }
    }

    func getTopProcessHistory(name: String, hours: Int = 24) -> [ProcessHistoryEntry] {
        let cutoff = Calendar.current.date(byAdding: .hour, value: -hours, to: Date())!
        return fetchHistory()
            .filter { $0.processName == name && $0.timestamp >= cutoff }
            .sorted { $0.timestamp > $1.timestamp }
    }

    func getMostActiveProcesses(hours: Int = 24, limit: Int = 5) -> [(name: String, avgCpu: Double, samples: Int)] {
        let cutoff = Calendar.current.date(byAdding: .hour, value: -hours, to: Date())!
        let recent = fetchHistory().filter { $0.timestamp >= cutoff }

        var processData: [String: (totalCpu: Double, count: Int)] = [:]
        for entry in recent {
            let current = processData[entry.processName] ?? (0, 0)
            processData[entry.processName] = (current.totalCpu + entry.cpuUsage, current.count + 1)
        }

        return processData.map { name, data in
            (name: name, avgCpu: data.totalCpu / Double(data.count), samples: data.count)
        }
        .sorted { $0.avgCpu > $1.avgCpu }
        .prefix(limit)
        .map { $0 }
    }

    func clearHistory() {
        UserDefaults.standard.removeObject(forKey: historyKey)
    }

    private func saveHistory(_ history: [ProcessHistoryEntry]) {
        do {
            let data = try JSONEncoder().encode(history)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            print("Failed to save process history: \(error)")
        }
    }
}
