import Foundation

struct SystemStats {
    var cpuUser: Double = 0
    var cpuSystem: Double = 0
    var cpuIdle: Double = 0
    var ramUsed: UInt64 = 0
    var ramTotal: UInt64 = 0
    var diskUsed: UInt64 = 0
    var diskTotal: UInt64 = 0
    var networkInDelta: UInt64 = 0
    var networkOutDelta: UInt64 = 0

    var ramPercentage: Double {
        guard ramTotal > 0 else { return 0 }
        return Double(ramUsed) / Double(ramTotal)
    }

    var diskPercentage: Double {
        guard diskTotal > 0 else { return 0 }
        return Double(diskUsed) / Double(diskTotal)
    }

    var cpuTotal: Double {
        return cpuUser + cpuSystem
    }

    static let zero = SystemStats()
}

struct Sample: Identifiable {
    let id: Int64
    let timestamp: Date
    let cpuUser: Double
    let cpuSystem: Double
    let cpuIdle: Double
    let ramUsed: Double
    let ramTotal: Double
    let diskUsed: Double
    let diskTotal: Double
    let networkInDelta: Double
    let networkOutDelta: Double

    var ramPercentage: Double {
        guard ramTotal > 0 else { return 0 }
        return ramUsed / ramTotal
    }

    var diskPercentage: Double {
        guard diskTotal > 0 else { return 0 }
        return diskUsed / diskTotal
    }
}
