import Foundation
import Darwin

final class SystemMonitor {
    static let shared = SystemMonitor()

    private let monitorQueue = DispatchQueue(label: "com.pulse.systemmonitor", qos: .userInitiated)
    private var timer: DispatchSourceTimer?

    private var previousCPUInfo: host_cpu_load_info?
    private var previousNetworkIn: UInt64 = 0
    private var previousNetworkOut: UInt64 = 0
    private var previousTimestamp: Date?

    var onStatsUpdate: ((SystemStats) -> Void)?

    private(set) var currentStats = SystemStats.zero

    private init() {}

    func start() {
        stop()

        let t = DispatchSource.makeTimerSource(queue: monitorQueue)
        t.schedule(deadline: .now(), repeating: 2.0)
        t.setEventHandler { [weak self] in
            self?.collectStats()
        }
        t.resume()
        timer = t
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    private func collectStats() {
        var stats = SystemStats()

        // CPU stats via host_statistics64
        let cpuStats = getCPUStats()
        stats.cpuUser = cpuStats.user
        stats.cpuSystem = cpuStats.system
        stats.cpuIdle = cpuStats.idle

        // RAM stats via vm_statistics64
        let ramStats = getRAMStats()
        stats.ramUsed = ramStats.used
        stats.ramTotal = ramStats.total

        // Disk stats
        let diskStats = getDiskStats()
        stats.diskUsed = diskStats.used
        stats.diskTotal = diskStats.total

        // Network stats
        let networkStats = getNetworkDelta()
        stats.networkInDelta = networkStats.bytesIn
        stats.networkOutDelta = networkStats.bytesOut

        currentStats = stats

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onStatsUpdate?(self.currentStats)
        }
    }

    // MARK: - CPU via host_statistics64
    private func getCPUStats() -> (user: Double, system: Double, idle: Double) {
        var size = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride)
        var cpuLoad = host_cpu_load_info()

        let result = withUnsafeMutablePointer(to: &cpuLoad) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
            }
        }

        guard result == KERN_SUCCESS else {
            return (0, 0, 100)
        }

        let user = Double(cpuLoad.cpu_ticks.0)
        let system = Double(cpuLoad.cpu_ticks.1)
        let idle = Double(cpuLoad.cpu_ticks.2)
        let nice = Double(cpuLoad.cpu_ticks.3)

        let total = user + system + idle + nice

        guard total > 0 else {
            return (0, 0, 100)
        }

        let userPct = (user / total) * 100
        let systemPct = (system / total) * 100
        let idlePct = (idle / total) * 100

        return (userPct, systemPct, idlePct)
    }

    // MARK: - RAM via vm_statistics64
    private func getRAMStats() -> (used: UInt64, total: UInt64) {
        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return (0, 0)
        }

        let pageSize = UInt64(vm_kernel_page_size)

        let _active = UInt64(vmStats.active_count) * pageSize
        let _inactive = UInt64(vmStats.inactive_count) * pageSize
        let _wired = UInt64(vmStats.wire_count) * pageSize
        let compressed = UInt64(vmStats.compressor_page_count) * pageSize
        let free = UInt64(vmStats.free_count) * pageSize

        // Get total physical memory
        let total = ProcessInfo.processInfo.physicalMemory

        // Used = total - free - compressed (more accurate)
        let used = total - free - compressed

        return (used, total)
    }

    // MARK: - Disk via FileManager
    private func getDiskStats() -> (used: UInt64, total: UInt64) {
        do {
            let attrs = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            let total = (attrs[.systemSize] as? UInt64) ?? 0
            let free = (attrs[.systemFreeSize] as? UInt64) ?? 0
            let used = total - free
            return (used, total)
        } catch {
            return (0, 0)
        }
    }

    // MARK: - Network via getifaddrs
    private func getNetworkDelta() -> (bytesIn: UInt64, bytesOut: UInt64) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return (0, 0)
        }

        defer { freeifaddrs(ifaddr) }

        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0

        var ptr = firstAddr
        while true {
            let interface = ptr.pointee

            // Skip loopback
            if interface.ifa_addr?.pointee.sa_family == UInt8(AF_LINK) {
                if let data = interface.ifa_data {
                    let networkData = data.assumingMemoryBound(to: if_data.self).pointee
                    // Check if not loopback (IFF_LOOPBACK flag is 0x8)
                    if (interface.ifa_flags & 0x8) == 0 {
                        totalIn += UInt64(networkData.ifi_ibytes)
                        totalOut += UInt64(networkData.ifi_obytes)
                    }
                }
            }

            guard let next = interface.ifa_next else { break }
            ptr = next
        }

        let now = Date()

        var deltaIn: UInt64 = 0
        var deltaOut: UInt64 = 0

        if let prev = previousTimestamp {
            let interval = now.timeIntervalSince(prev)
            if interval > 0 {
                if totalIn >= previousNetworkIn {
                    deltaIn = totalIn - previousNetworkIn
                }
                if totalOut >= previousNetworkOut {
                    deltaOut = totalOut - previousNetworkOut
                }
            }
        }

        previousNetworkIn = totalIn
        previousNetworkOut = totalOut
        previousTimestamp = now

        return (deltaIn, deltaOut)
    }
}
