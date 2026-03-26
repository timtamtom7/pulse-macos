import SwiftUI

// MARK: - Dashboard View

struct DashboardView: View {
    @StateObject private var remoteService = RemoteMonitoringService.shared
    @State private var showAddMac = false
    @State private var newMacName = ""
    @State private var newMacHostname = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Mac Dashboard")
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer()

                    Button("Discover") {
                        remoteService.discoverMacs()
                    }
                    .buttonStyle(.bordered)
                    .disabled(remoteService.isDiscovering)

                    Button("+ Add Mac") {
                        showAddMac = true
                    }
                    .buttonStyle(.borderedProminent)
                }

                if remoteService.isDiscovering {
                    HStack {
                        ProgressView()
                        Text("Discovering Macs on network...")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }

                // Alerts
                if let dashboard = remoteService.dashboard, !dashboard.alerts.isEmpty {
                    alertsSection(dashboard.alerts)
                }

                // Mac Grid
                if remoteService.remoteMacs.isEmpty {
                    emptyState
                } else {
                    macGrid
                }
            }
            .padding()
        }
        .sheet(isPresented: $showAddMac) {
            addMacSheet
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "desktopcomputer")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Macs Connected")
                .font(.headline)

            Text("Add a Mac to monitor its system stats remotely")
                .foregroundColor(.secondary)

            Button("Add Mac") {
                showAddMac = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
    }

    private func alertsSection(_ alerts: [DashboardAlert]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Active Alerts")
                    .font(.headline)
            }

            ForEach(alerts) { alert in
                HStack {
                    Circle()
                        .fill(severityColor(alert.severity))
                        .frame(width: 8, height: 8)

                    Text(alert.macName)
                        .fontWeight(.medium)

                    Text(alert.message)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(formatDate(alert.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }

    private var macGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
            ForEach(remoteService.remoteMacs) { mac in
                MacCard(mac: mac, onRefresh: {
                    Task {
                        await remoteService.refreshMacStatus(mac.id)
                    }
                })
            }
        }
    }

    private var addMacSheet: some View {
        VStack(spacing: 16) {
            Text("Add Mac")
                .font(.title2)
                .fontWeight(.bold)

            TextField("Mac Name", text: $newMacName)
                .textFieldStyle(.roundedBorder)

            TextField("Hostname (e.g., macbook.local)", text: $newMacHostname)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel") {
                    showAddMac = false
                }
                .buttonStyle(.bordered)

                Button("Add") {
                    _ = remoteService.addMac(name: newMacName, hostname: newMacHostname)
                    showAddMac = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(newMacName.isEmpty || newMacHostname.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 350)
    }

    private func severityColor(_ severity: AlertSeverity) -> Color {
        switch severity {
        case .info: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Mac Card

struct MacCard: View {
    let mac: RemoteMac
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "desktopcomputer")
                    .font(.title2)
                    .foregroundColor(mac.isOnline ? .green : .secondary)

                VStack(alignment: .leading) {
                    Text(mac.name)
                        .font(.headline)
                    Text(mac.isOnline ? "Online" : "Offline")
                        .font(.caption)
                        .foregroundColor(mac.isOnline ? .green : .secondary)
                }

                Spacer()

                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Stats
            if let stats = mac.systemStats {
                VStack(spacing: 8) {
                    statRow("CPU", value: "\(Int(stats.cpuUsage))%", color: cpuColor(stats.cpuUsage))
                    statRow("Memory", value: "\(Int(stats.memoryUsage))%", color: memoryColor(stats.memoryUsage))
                    statRow("Disk", value: "\(Int(stats.diskUsage))%", color: diskColor(stats.diskUsage))
                    if stats.temperature > 0 {
                        statRow("Temp", value: "\(Int(stats.temperature))°C", color: tempColor(stats.temperature))
                    }
                }
            } else if mac.isOnline {
                Text("Loading stats...")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                Text("No data available")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private func statRow(_ label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }

    private func cpuColor(_ value: Double) -> Color {
        switch value {
        case 0..<60: return .green
        case 60..<85: return .orange
        default: return .red
        }
    }

    private func memoryColor(_ value: Double) -> Color {
        switch value {
        case 0..<70: return .green
        case 70..<90: return .orange
        default: return .red
        }
    }

    private func diskColor(_ value: Double) -> Color {
        switch value {
        case 0..<80: return .green
        case 80..<95: return .orange
        default: return .red
        }
    }

    private func tempColor(_ value: Double) -> Color {
        switch value {
        case 0..<60: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }
}

// MARK: - Historical Reports View

struct HistoricalReportsView: View {
    @StateObject private var reportService = HistoricalReportService.shared
    @State private var selectedReportType: ReportType = .weekly

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Historical Reports")
                    .font(.title2)
                    .fontWeight(.bold)

                // Report Type Picker
                Picker("Report Type", selection: $selectedReportType) {
                    Text("Weekly").tag(ReportType.weekly)
                    Text("Monthly").tag(ReportType.monthly)
                    Text("Yearly").tag(ReportType.yearly)
                }
                .pickerStyle(.segmented)

                Button("Generate Report") {
                    generateReport()
                }
                .buttonStyle(.borderedProminent)

                // Recent Reports
                if !reportService.reports.isEmpty {
                    Text("Recent Reports")
                        .font(.headline)

                    ForEach(reportService.reports) { report in
                        reportRow(report)
                    }
                }
            }
            .padding()
        }
    }

    private func generateReport() {
        let report: HistoricalReport
        switch selectedReportType {
        case .weekly:
            report = reportService.generateWeeklyReport()
        case .monthly:
            report = reportService.generateMonthlyReport()
        default:
            report = reportService.generateWeeklyReport()
        }
        reportService.reports.insert(report, at: 0)
    }

    private func reportRow(_ report: HistoricalReport) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(report.type.rawValue) Report")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(formatDate(report.startDate)) - \(formatDate(report.endDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("Avg CPU: \(Int(report.summary.avgCPU))%")
                    .font(.caption)
                Text("\(report.anomalies.count) anomalies")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button("Export") {
                if let url = reportService.exportReportCSV(report) {
                    NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
