import Foundation

// MARK: - Remote Mac Model

struct RemoteMac: Identifiable, Codable {
    let id: UUID
    var name: String
    var hostname: String
    var ipAddress: String
    var port: Int
    var isOnline: Bool
    var lastSeen: Date
    var systemStats: SystemStatsSnapshot?
    var apiKey: String

    init(
        id: UUID = UUID(),
        name: String,
        hostname: String,
        ipAddress: String,
        port: Int = 9876,
        isOnline: Bool = false,
        lastSeen: Date = Date(),
        systemStats: SystemStatsSnapshot? = nil,
        apiKey: String = UUID().uuidString
    ) {
        self.id = id
        self.name = name
        self.hostname = hostname
        self.ipAddress = ipAddress
        self.port = port
        self.isOnline = isOnline
        self.lastSeen = lastSeen
        self.systemStats = systemStats
        self.apiKey = apiKey
    }
}

struct SystemStatsSnapshot: Codable {
    let timestamp: Date
    let cpuUsage: Double
    let memoryUsage: Double
    let diskUsage: Double
    let temperature: Double
    let networkUp: Double
    let networkDown: Double
    let batteryPercent: Int?
}

// MARK: - Watch Status

struct WatchStatus: Codable {
    var macName: String
    var cpuUsage: Int
    var memoryUsage: Int
    var temperature: Int?
    var batteryPercent: Int?
    var isAlert: Bool
    var alertMessage: String?
    var lastUpdated: Date

    init(
        macName: String = "",
        cpuUsage: Int = 0,
        memoryUsage: Int = 0,
        temperature: Int? = nil,
        batteryPercent: Int? = nil,
        isAlert: Bool = false,
        alertMessage: String? = nil,
        lastUpdated: Date = Date()
    ) {
        self.macName = macName
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.temperature = temperature
        self.batteryPercent = batteryPercent
        self.isAlert = isAlert
        self.alertMessage = alertMessage
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Historical Report

struct HistoricalReport: Identifiable, Codable {
    let id: UUID
    var type: ReportType
    var startDate: Date
    var endDate: Date
    var generatedAt: Date
    var summary: ReportSummary
    var anomalies: [AnomalyEvent]
    var recommendations: [String]

    init(
        id: UUID = UUID(),
        type: ReportType,
        startDate: Date,
        endDate: Date,
        generatedAt: Date = Date(),
        summary: ReportSummary = ReportSummary(),
        anomalies: [AnomalyEvent] = [],
        recommendations: [String] = []
    ) {
        self.id = id
        self.type = type
        self.startDate = startDate
        self.endDate = endDate
        self.generatedAt = generatedAt
        self.summary = summary
        self.anomalies = anomalies
        self.recommendations = recommendations
    }
}

enum ReportType: String, Codable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    case custom = "Custom"
}

struct ReportSummary: Codable {
    var avgCPU: Double
    var peakCPU: Double
    var avgMemory: Double
    var peakMemory: Double
    var avgTemperature: Double
    var peakTemperature: Double
    var uptimePercent: Double
    var totalAlerts: Int

    init(
        avgCPU: Double = 0,
        peakCPU: Double = 0,
        avgMemory: Double = 0,
        peakMemory: Double = 0,
        avgTemperature: Double = 0,
        peakTemperature: Double = 0,
        uptimePercent: Double = 100,
        totalAlerts: Int = 0
    ) {
        self.avgCPU = avgCPU
        self.peakCPU = peakCPU
        self.avgMemory = avgMemory
        self.peakMemory = peakMemory
        self.avgTemperature = avgTemperature
        self.peakTemperature = peakTemperature
        self.uptimePercent = uptimePercent
        self.totalAlerts = totalAlerts
    }
}

struct AnomalyEvent: Identifiable, Codable {
    let id: UUID
    var timestamp: Date
    var type: AnomalyType
    var metric: String
    var value: Double
    var threshold: Double
    var description: String

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        type: AnomalyType,
        metric: String,
        value: Double,
        threshold: Double,
        description: String = ""
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.metric = metric
        self.value = value
        self.threshold = threshold
        self.description = description
    }
}

enum AnomalyType: String, Codable {
    case highCPU = "High CPU"
    case highMemory = "High Memory"
    case highTemperature = "High Temperature"
    case diskFull = "Disk Full"
    case networkIssue = "Network Issue"
}

// MARK: - Dashboard

struct MacDashboard: Identifiable, Codable {
    let id: UUID
    var macs: [RemoteMac]
    var alerts: [DashboardAlert]
    var lastUpdated: Date

    init(
        id: UUID = UUID(),
        macs: [RemoteMac] = [],
        alerts: [DashboardAlert] = [],
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.macs = macs
        self.alerts = alerts
        self.lastUpdated = lastUpdated
    }
}

struct DashboardAlert: Identifiable, Codable {
    let id: UUID
    var macId: UUID
    var macName: String
    var severity: AlertSeverity
    var message: String
    var timestamp: Date
    var isAcknowledged: Bool

    init(
        id: UUID = UUID(),
        macId: UUID,
        macName: String,
        severity: AlertSeverity,
        message: String,
        timestamp: Date = Date(),
        isAcknowledged: Bool = false
    ) {
        self.id = id
        self.macId = macId
        self.macName = macName
        self.severity = severity
        self.message = message
        self.timestamp = timestamp
        self.isAcknowledged = isAcknowledged
    }
}

enum AlertSeverity: String, Codable {
    case info = "Info"
    case warning = "Warning"
    case critical = "Critical"
}
