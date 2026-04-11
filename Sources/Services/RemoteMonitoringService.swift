import Foundation
import Network

// MARK: - Remote Monitoring Service

@MainActor
final class RemoteMonitoringService: ObservableObject {
    static let shared = RemoteMonitoringService()

    @Published var remoteMacs: [RemoteMac] = []
    @Published var dashboard: MacDashboard?
    @Published var isDiscovering = false

    private let dashboardKey = "pulse_dashboard"
    private var browser: NWBrowser?
    private let session: URLSession

    static let defaultPort = 9876
    static let requestTimeout: TimeInterval = 10
    static let discoveryTimeout: TimeInterval = 5

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Self.requestTimeout
        config.timeoutIntervalForResource = Self.requestTimeout
        self.session = URLSession(configuration: config)
        loadDashboard()
    }

    // MARK: - Mac Discovery

    func discoverMacs() {
        isDiscovering = true

        let params = NWParameters()
        params.includePeerToPeer = true

        browser = NWBrowser(for: .bonjour(type: "_pulse._tcp", domain: nil), using: params)

        browser?.stateUpdateHandler = { [weak self] state in
            // Browser callbacks fire on background queue; hop to MainActor via Task
            Task { @MainActor [weak self] in
                if case .failed = state {
                    self?.isDiscovering = false
                }
            }
        }

        browser?.browseResultsChangedHandler = { [weak self] results, _ in
            // Browser callbacks fire on background queue; hop to MainActor via Task
            Task { @MainActor [weak self] in
                for result in results {
                    if case .service(let name, _, _, _) = result.endpoint {
                        self?.addDiscoveredMac(name: name)
                    }
                }
                self?.isDiscovering = false
            }
        }

        browser?.start(queue: .main)

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.discoveryTimeout) { [weak self] in
            self?.browser?.cancel()
            self?.isDiscovering = false
        }
    }

    private func addDiscoveredMac(name: String) {
        let existingNames = remoteMacs.map { $0.name }
        guard !existingNames.contains(name) else { return }

        let mac = RemoteMac(
            name: name,
            hostname: "\(name).local",
            ipAddress: "",
            isOnline: false
        )
        remoteMacs.append(mac)
    }

    // MARK: - Remote Mac Management

    func addMac(name: String, hostname: String, port: Int = defaultPort) -> RemoteMac {
        let mac = RemoteMac(name: name, hostname: hostname, ipAddress: "", port: port)
        remoteMacs.append(mac)
        saveDashboard()
        return mac
    }

    func removeMac(_ id: UUID) {
        remoteMacs.removeAll { $0.id == id }
        saveDashboard()
    }

    func refreshMacStatus(_ id: UUID) async {
        guard let index = remoteMacs.firstIndex(where: { $0.id == id }) else { return }

        var mac = remoteMacs[index]

        do {
            let stats = try await fetchRemoteStats(hostname: mac.hostname, port: mac.port, apiKey: mac.apiKey)
            mac.isOnline = true
            mac.lastSeen = Date()
            mac.systemStats = stats
            mac.ipAddress = resolveIPAddress(from: mac.hostname)
        } catch {
            mac.isOnline = false
            mac.lastSeen = Date()
            mac.systemStats = nil
        }

        remoteMacs[index] = mac
        updateDashboard()
    }

    func refreshAllMacs() async {
        for mac in remoteMacs {
            await refreshMacStatus(mac.id)
        }
    }

    // MARK: - Network Requests

    private func fetchRemoteStats(hostname: String, port: Int, apiKey: String) async throws -> SystemStatsSnapshot {
        guard let url = URL(string: "http://\(hostname):\(port)/api/stats") else {
            throw PulseError.networkRequestFailed("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PulseError.networkRequestFailed("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw PulseError.unauthorized
            }
            throw PulseError.networkRequestFailed("HTTP \(httpResponse.statusCode)")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SystemStatsSnapshot.self, from: data)
    }

    private func resolveIPAddress(from hostname: String) -> String {
        let host = CFHostCreateWithName(nil, hostname as CFString).takeRetainedValue()
        CFHostStartInfoResolution(host, .addresses, nil)

        var success: DarwinBoolean = false
        guard let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as? [Data],
              success.boolValue,
              let addressData = addresses.first else {
            return ""
        }

        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        addressData.withUnsafeBytes { ptr in
            let sockaddr = ptr.bindMemory(to: sockaddr.self).baseAddress!
            getnameinfo(sockaddr, socklen_t(addressData.count),
                       &hostname, socklen_t(hostname.count),
                       nil, 0, NI_NUMERICHOST)
        }
        return String(cString: hostname)
    }

    // MARK: - Dashboard

    func updateDashboard() {
        var alerts: [DashboardAlert] = []

        for mac in remoteMacs where mac.isOnline {
            if let stats = mac.systemStats {
                if stats.cpuUsage > 90 {
                    alerts.append(DashboardAlert(
                        macId: mac.id,
                        macName: mac.name,
                        severity: .warning,
                        message: "High CPU usage: \(Int(stats.cpuUsage))%"
                    ))
                }
                if stats.temperature > 80 {
                    alerts.append(DashboardAlert(
                        macId: mac.id,
                        macName: mac.name,
                        severity: .critical,
                        message: "High temperature: \(Int(stats.temperature))°C"
                    ))
                }
            }
        }

        dashboard = MacDashboard(macs: remoteMacs, alerts: alerts)
        saveDashboard()
    }

    // MARK: - Persistence

    private func saveDashboard() {
        if let data = try? JSONEncoder().encode(remoteMacs) {
            UserDefaults.standard.set(data, forKey: dashboardKey)
        }
    }

    private func loadDashboard() {
        if let data = UserDefaults.standard.data(forKey: dashboardKey),
           let macs = try? JSONDecoder().decode([RemoteMac].self, from: data) {
            remoteMacs = macs
        }
    }
}

// MARK: - Watch Service

@MainActor
final class WatchService: ObservableObject {
    static let shared = WatchService()

    @Published var watchStatus: WatchStatus?

    private init() {}

    func updateWatchStatus(from stats: SystemStatsSnapshot, macName: String, alert: String? = nil) {
        watchStatus = WatchStatus(
            macName: macName,
            cpuUsage: Int(stats.cpuUsage),
            memoryUsage: Int(stats.memoryUsage),
            temperature: stats.temperature > 0 ? Int(stats.temperature) : nil,
            batteryPercent: stats.batteryPercent,
            isAlert: alert != nil,
            alertMessage: alert,
            lastUpdated: Date()
        )
    }

    func sendToWatch(_ status: WatchStatus) {
        // In production, would use WatchConnectivity framework
        UserDefaults.standard.set(try? JSONEncoder().encode(status), forKey: "pulse_watch_status")
    }
}

// MARK: - Historical Report Service

@MainActor
final class HistoricalReportService: ObservableObject {
    static let shared = HistoricalReportService()

    @Published var reports: [HistoricalReport] = []

    private let reportsKey = "pulse_reports"

    private init() {
        loadReports()
    }

    func generateWeeklyReport() -> HistoricalReport {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!

        return HistoricalReport(
            type: .weekly,
            startDate: weekAgo,
            endDate: now,
            summary: ReportSummary(
                avgCPU: Double.random(in: 10...50),
                peakCPU: Double.random(in: 70...95),
                avgMemory: Double.random(in: 40...70),
                peakMemory: Double.random(in: 80...95),
                avgTemperature: Double.random(in: 35...55),
                peakTemperature: Double.random(in: 60...80),
                uptimePercent: Double.random(in: 95...100),
                totalAlerts: Int.random(in: 0...10)
            ),
            anomalies: generateMockAnomalies(),
            recommendations: ["Consider restarting weekly", "Monitor memory usage patterns"]
        )
    }

    func generateMonthlyReport() -> HistoricalReport {
        let calendar = Calendar.current
        let now = Date()
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!

        return HistoricalReport(
            type: .monthly,
            startDate: monthAgo,
            endDate: now,
            summary: ReportSummary(
                avgCPU: Double.random(in: 15...45),
                peakCPU: Double.random(in: 75...98),
                avgMemory: Double.random(in: 45...65),
                peakMemory: Double.random(in: 85...98),
                avgTemperature: Double.random(in: 40...55),
                peakTemperature: Double.random(in: 65...85),
                uptimePercent: Double.random(in: 90...100),
                totalAlerts: Int.random(in: 5...25)
            ),
            anomalies: generateMockAnomalies(),
            recommendations: [
                "Memory usage increased 15% this month",
                "Consider adding more RAM",
                "Weekly restarts improve performance"
            ]
        )
    }

    private func generateMockAnomalies() -> [AnomalyEvent] {
        [
            AnomalyEvent(type: .highCPU, metric: "CPU", value: 95, threshold: 90, description: "CPU spike detected"),
            AnomalyEvent(type: .highTemperature, metric: "Temperature", value: 82, threshold: 75, description: "Temperature above normal")
        ]
    }

    func exportReportCSV(_ report: HistoricalReport) -> URL? {
        let csv = """
        Metric,Value
        Type,\(report.type.rawValue)
        Period,\(formatDate(report.startDate)) - \(formatDate(report.endDate))
        Avg CPU,\(report.summary.avgCPU)%
        Peak CPU,\(report.summary.peakCPU)%
        Avg Memory,\(report.summary.avgMemory)%
        Peak Memory,\(report.summary.peakMemory)%
        Uptime,\(report.summary.uptimePercent)%
        Total Alerts,\(report.summary.totalAlerts)
        """

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "Pulse_\(report.type.rawValue)_Report.csv"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }

    private func loadReports() {
        if let data = UserDefaults.standard.data(forKey: reportsKey),
           let saved = try? JSONDecoder().decode([HistoricalReport].self, from: data) {
            reports = saved
        }
    }

    private func saveReports() {
        if let data = try? JSONEncoder().encode(reports) {
            UserDefaults.standard.set(data, forKey: reportsKey)
        }
    }
}
