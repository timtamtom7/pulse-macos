import Foundation
import SQLite

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

    private var db: Connection?

    private let processHistory = Table("process_history")
    private let id = Expression<String>("id")
    private let processName = Expression<String>("process_name")
    private let pid = Expression<Int64>("pid")
    private let cpuUsage = Expression<Double>("cpu_usage")
    private let memoryUsage = Expression<Int64>("memory_usage")
    private let timestamp = Expression<Date>("timestamp")

    static let maxEntries = 1000

    private init() {
        setupDatabase()
    }

    private func setupDatabase() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let pulseDir = appSupport.appendingPathComponent("Pulse", isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: pulseDir, withIntermediateDirectories: true)
            let dbPath = pulseDir.appendingPathComponent("pulse.db").path
            db = try Connection(dbPath)
            // Enable WAL mode for concurrent reads from widget and main app
            try db?.execute("PRAGMA journal_mode=WAL")
            try createTables()
        } catch {
            print("Process history database setup failed: \(error)")
        }
    }

    private func createTables() throws {
        try db?.run(processHistory.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(processName)
            t.column(pid)
            t.column(cpuUsage)
            t.column(memoryUsage)
            t.column(timestamp)
        })

        try db?.run(processHistory.createIndex(timestamp, ifNotExists: true))
        try db?.run(processHistory.createIndex(processName, ifNotExists: true))
    }

    func recordTopProcesses(_ processes: [AppProcessInfo]) {
        guard let db = db else { return }

        for process in processes.prefix(5) {
            let entry = ProcessHistoryEntry(
                id: UUID(),
                processName: process.name,
                pid: process.id,
                cpuUsage: process.cpuUsage,
                memoryUsage: process.memoryUsage,
                timestamp: Date()
            )

            do {
                try db.run(processHistory.insert(
                    id <- entry.id.uuidString,
                    processName <- entry.processName,
                    pid <- Int64(entry.pid),
                    cpuUsage <- entry.cpuUsage,
                    memoryUsage <- Int64(entry.memoryUsage),
                    timestamp <- entry.timestamp
                ))
            } catch {
                print("Failed to record process history: \(error)")
            }
        }

        purgeOldEntries()
    }

    func fetchHistory() -> [ProcessHistoryEntry] {
        guard let db = db else { return [] }

        var result: [ProcessHistoryEntry] = []

        do {
            for row in try db.prepare(processHistory.order(timestamp.desc).limit(Self.maxEntries)) {
                if let uuid = UUID(uuidString: row[id]) {
                    let entry = ProcessHistoryEntry(
                        id: uuid,
                        processName: row[processName],
                        pid: Int32(row[pid]),
                        cpuUsage: row[cpuUsage],
                        memoryUsage: UInt64(row[memoryUsage]),
                        timestamp: row[timestamp]
                    )
                    result.append(entry)
                }
            }
        } catch {
            print("Failed to fetch process history: \(error)")
        }

        return result
    }

    func getTopProcessHistory(name: String, hours: Int = 24) -> [ProcessHistoryEntry] {
        guard let db = db else { return [] }

        let cutoff = Calendar.current.date(byAdding: .hour, value: -hours, to: Date())!
        var result: [ProcessHistoryEntry] = []

        do {
            let query = processHistory
                .filter(processName == name && timestamp >= cutoff)
                .order(timestamp.desc)

            for row in try db.prepare(query) {
                if let uuid = UUID(uuidString: row[id]) {
                    let entry = ProcessHistoryEntry(
                        id: uuid,
                        processName: row[processName],
                        pid: Int32(row[pid]),
                        cpuUsage: row[cpuUsage],
                        memoryUsage: UInt64(row[memoryUsage]),
                        timestamp: row[timestamp]
                    )
                    result.append(entry)
                }
            }
        } catch {
            print("Failed to fetch process history: \(error)")
        }

        return result
    }

    func getMostActiveProcesses(hours: Int = 24, limit: Int = 5) -> [(name: String, avgCpu: Double, samples: Int)] {
        guard let db = db else { return [] }

        let cutoff = Calendar.current.date(byAdding: .hour, value: -hours, to: Date())!

        do {
            let query = processHistory
                .select(processName, cpuUsage.sum, cpuUsage.count)
                .filter(timestamp >= cutoff)
                .group(processName)
                .order(cpuUsage.sum.desc)
                .limit(limit)

            var result: [(name: String, avgCpu: Double, samples: Int)] = []

            for row in try db.prepare(query) {
                let name = row[processName]
                let totalCpu = row[cpuUsage.sum] ?? 0
                let count = row[cpuUsage.count]
                let avgCpu = count > 0 ? totalCpu / Double(count) : 0
                result.append((name: name, avgCpu: avgCpu, samples: count))
            }

            return result
        } catch {
            print("Failed to fetch active processes: \(error)")
            return []
        }
    }

    func clearHistory() {
        guard let db = db else { return }
        do {
            try db.run(processHistory.delete())
        } catch {
            print("Failed to clear process history: \(error)")
        }
    }

    private func purgeOldEntries() {
        guard let db = db else { return }

        do {
            let count = try db.scalar(processHistory.count)
            if count > Self.maxEntries {
                let excess = count - Self.maxEntries
                let oldestEntries = processHistory
                    .order(timestamp.asc)
                    .limit(excess)

                let idsToDelete = try db.prepare(oldestEntries).map { $0[id] }
                try db.run(processHistory.filter(idsToDelete.contains(id)).delete())
            }
        } catch {
            print("Failed to purge old entries: \(error)")
        }
    }
}
