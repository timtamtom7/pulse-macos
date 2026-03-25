import Foundation

// MARK: - SystemStats

struct SystemStats {
    var cpuUser: Double = 0
    var cpuSystem: Double = 0
    var cpuIdle: Double = 100
    var ramUsed: UInt64 = 0
    var ramTotal: UInt64 = 0
    var diskUsed: UInt64 = 0
    var diskTotal: UInt64 = 0
    var networkInDelta: UInt64 = 0
    var networkOutDelta: UInt64 = 0
    var bandwidthIn: Double = 0
    var bandwidthOut: Double = 0

    var cpuTotal: Double { cpuUser + cpuSystem }

    var ramPercentage: Double {
        guard ramTotal > 0 else { return 0 }
        return Double(ramUsed) / Double(ramTotal)
    }

    var diskPercentage: Double {
        guard diskTotal > 0 else { return 0 }
        return Double(diskUsed) / Double(diskTotal)
    }

    static let zero = SystemStats()
}

// MARK: - Sample (Historical Data Point)

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

    var cpuTotal: Double {
        cpuUser + cpuSystem
    }

    var ramPercentage: Double {
        guard ramTotal > 0 else { return 0 }
        return ramUsed / ramTotal
    }

    var diskPercentage: Double {
        guard diskTotal > 0 else { return 0 }
        return diskUsed / diskTotal
    }

    var hour: Int {
        Calendar.current.component(.hour, from: timestamp)
    }

    var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: timestamp)
    }
}

// MARK: - Hourly Sample Aggregate

struct HourlySample: Identifiable {
    let id = UUID()
    let hour: Int
    let date: Date
    let avgCpuUser: Double
    let avgCpuSystem: Double
    let avgRamUsed: Double
    let peakCpu: Double
    let avgNetworkIn: Double
    let avgNetworkOut: Double

    var avgCpuTotal: Double { avgCpuUser + avgCpuSystem }
}

// MARK: - Process Info

struct AppProcessInfo: Identifiable {
    let id: Int32
    let name: String
    let cpuUsage: Double
    let memoryUsage: UInt64
    let user: String

    var memoryString: String {
        let mb = Double(memoryUsage) / 1_000_000
        return String(format: "%.1f MB", mb)
    }

    var cpuString: String {
        String(format: "%.1f%%", cpuUsage)
    }
}

// MARK: - Process Monitor

import Darwin

final class ProcessMonitor {
    static let shared = ProcessMonitor()

    private init() {}

    func getTopProcesses(limit: Int = 10) -> [AppProcessInfo] {
        var processes: [AppProcessInfo] = []

        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        var size: Int = 0

        guard sysctl(&mib, 4, nil, &size, nil, 0) == 0 else { return [] }
        let count = size / MemoryLayout<kinfo_proc>.stride

        var procList = [kinfo_proc](repeating: kinfo_proc(), count: count)
        guard sysctl(&mib, 4, &procList, &size, nil, 0) == 0 else { return [] }

        let actualCount = size / MemoryLayout<kinfo_proc>.stride

        for i in 0..<actualCount {
            let proc = procList[i]
            let pid = proc.kp_proc.p_pid
            let name = withUnsafePointer(to: proc.kp_proc.p_comm) { ptr in
                ptr.withMemoryRebound(to: CChar.self, capacity: Int(MAXCOMLEN)) { cString in
                    String(cString: cString)
                }
            }

            // Skip system processes and current process
            guard pid > 0, name != "login" else { continue }

            // Get CPU and memory via task_info
            let cpuUsage = getCPUUsage(for: pid)
            let memoryUsage = getMemoryUsage(for: pid)
            let user = getProcessUser(for: proc.kp_eproc.e_ucred.cr_uid)

            if cpuUsage > 0 || memoryUsage > 0 {
                processes.append(AppProcessInfo(
                    id: pid,
                    name: name,
                    cpuUsage: cpuUsage,
                    memoryUsage: memoryUsage,
                    user: user
                ))
            }
        }

        return processes
            .sorted { $0.cpuUsage > $1.cpuUsage }
            .prefix(limit)
            .map { $0 }
    }

    private func getCPUUsage(for pid: Int32) -> Double {
        var taskInfo = task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &taskInfo) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else { return 0 }

        // Simple CPU approximation using user + system time
        var rusageInfo = rusage_info_v0()
        var rusageSize = MemoryLayout<rusage_info_v0>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]

        let res = sysctl(&mib, 4, &rusageInfo, &rusageSize, nil, 0)
        guard res == 0 else { return 0 }

        let totalTime = Double(rusageInfo.ri_user_time + rusageInfo.ri_system_time) / 1_000_000_000.0

        // Very rough approximation - this is a simplification
        return min(totalTime, 100.0)
    }

    private func getMemoryUsage(for pid: Int32) -> UInt64 {
        var taskInfo = task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &taskInfo) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else { return 0 }
        return UInt64(taskInfo.resident_size)
    }

    private func getProcessUser(for uid: uid_t) -> String {
        if let pwd = getpwuid(uid) {
            return String(cString: pwd.pointee.pw_name)
        }
        return "\(uid)"
    }
}
