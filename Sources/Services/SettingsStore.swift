import Foundation
import SQLite

final class SettingsStore {
    static let shared = SettingsStore()

    private var db: Connection?

    // Table & Columns
    private let samples = Table("samples")
    private let id = Expression<Int64>("id")
    private let timestamp = Expression<Date>("timestamp")
    private let cpuUser = Expression<Double>("cpu_user")
    private let cpuSystem = Expression<Double>("cpu_system")
    private let cpuIdle = Expression<Double>("cpu_idle")
    private let ramUsed = Expression<Double>("ram_used")
    private let ramTotal = Expression<Double>("ram_total")
    private let diskUsed = Expression<Double>("disk_used")
    private let diskTotal = Expression<Double>("disk_total")
    private let networkInDelta = Expression<Double>("network_in_delta")
    private let networkOutDelta = Expression<Double>("network_out_delta")

    private let retentionDays = 7
    private let sampleIntervalSeconds: Double = 60

    private var lastSampleTime: Date?

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
            try createTables()
            try purgeOldSamples()
        } catch {
            print("Database setup failed: \(error)")
        }
    }

    private func createTables() throws {
        try db?.run(samples.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(timestamp)
            t.column(cpuUser)
            t.column(cpuSystem)
            t.column(cpuIdle)
            t.column(ramUsed)
            t.column(ramTotal)
            t.column(diskUsed)
            t.column(diskTotal)
            t.column(networkInDelta)
            t.column(networkOutDelta)
        })
    }

    func recordSample(_ stats: SystemStats) {
        let now = Date()

        if let last = lastSampleTime, now.timeIntervalSince(last) < sampleIntervalSeconds {
            return
        }

        lastSampleTime = now

        let intervalSeconds: Double = 2.0
        let netInPerSec = stats.networkInDelta > 0 ? Double(stats.networkInDelta) / intervalSeconds : 0
        let netOutPerSec = stats.networkOutDelta > 0 ? Double(stats.networkOutDelta) / intervalSeconds : 0

        do {
            try db?.run(samples.insert(
                timestamp <- now,
                cpuUser <- stats.cpuUser,
                cpuSystem <- stats.cpuSystem,
                cpuIdle <- stats.cpuIdle,
                ramUsed <- Double(stats.ramUsed),
                ramTotal <- Double(stats.ramTotal),
                diskUsed <- Double(stats.diskUsed),
                diskTotal <- Double(stats.diskTotal),
                networkInDelta <- netInPerSec,
                networkOutDelta <- netOutPerSec
            ))
        } catch {
            print("Failed to record sample: \(error)")
        }
    }

    func getRecentSamples(hours: Int = 24) -> [Sample] {
        guard let db = db else { return [] }

        let cutoff = Date().addingTimeInterval(-Double(hours * 3600))
        var result: [Sample] = []

        do {
            for row in try db.prepare(samples.filter(timestamp >= cutoff).order(timestamp.asc)) {
                let sample = Sample(
                    id: row[id],
                    timestamp: row[timestamp],
                    cpuUser: row[cpuUser],
                    cpuSystem: row[cpuSystem],
                    cpuIdle: row[cpuIdle],
                    ramUsed: row[ramUsed],
                    ramTotal: row[ramTotal],
                    diskUsed: row[diskUsed],
                    diskTotal: row[diskTotal],
                    networkInDelta: row[networkInDelta],
                    networkOutDelta: row[networkOutDelta]
                )
                result.append(sample)
            }
        } catch {
            print("Failed to fetch samples: \(error)")
        }

        return result
    }

    private func purgeOldSamples() throws {
        let cutoff = Date().addingTimeInterval(-Double(retentionDays * 24 * 3600))
        try db?.run(samples.filter(timestamp < cutoff).delete())
    }
}
