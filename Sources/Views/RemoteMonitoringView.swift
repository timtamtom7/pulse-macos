import SwiftUI

// MARK: - Dashboard View

struct DashboardView: View {
    @StateObject private var remoteService = RemoteMonitoringService.shared
    @State private var showAddMac = false
    @State private var newMacName = ""
    @State private var newMacHostname = ""

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.paddingMedium) {
                headerView

                if remoteService.isDiscovering {
                    discoveringView
                }

                if let dashboard = remoteService.dashboard, !dashboard.alerts.isEmpty {
                    alertsSection(dashboard.alerts)
                }

                if remoteService.remoteMacs.isEmpty {
                    emptyState
                } else {
                    macGrid
                }
            }
            .padding(Theme.paddingMedium)
        }
        .sheet(isPresented: $showAddMac) {
            addMacSheet
        }
    }

    private var headerView: some View {
        HStack {
            Text("Mac Dashboard")
                .font(.system(size: Theme.fontSizeLarge, weight: .bold))
                .foregroundColor(Theme.textPrimary)

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
    }

    private var discoveringView: some View {
        HStack {
            ProgressView()
            Text("Discovering Macs on network...")
                .font(.system(size: Theme.fontSizeBody))
                .foregroundColor(Theme.textSecondary)
        }
        .padding(Theme.paddingMedium)
    }

    private var emptyState: some View {
        VStack(spacing: Theme.paddingMedium) {
            Image(systemName: "desktopcomputer")
                .font(.system(size: Theme.fontSizeLarge))
                .foregroundColor(Theme.textSecondary)

            Text("No Macs Connected")
                .font(.system(size: Theme.fontSizeSubheadline, weight: .medium))
                .foregroundColor(Theme.textPrimary)

            Text("Add a Mac to monitor its system stats remotely")
                .font(.system(size: Theme.fontSizeBody))
                .foregroundColor(Theme.textSecondary)

            Button("Add Mac") {
                showAddMac = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(Theme.paddingLarge)
    }

    private func alertsSection(_ alerts: [DashboardAlert]) -> some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Theme.alertWarning)
                Text("Active Alerts")
                    .font(.system(size: Theme.fontSizeBody, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
            }

            ForEach(alerts) { alert in
                HStack {
                    Circle()
                        .fill(severityColor(alert.severity))
                        .frame(width: 8, height: 8)

                    Text(alert.macName)
                        .font(.system(size: Theme.fontSizeBody, weight: .medium))
                        .foregroundColor(Theme.textPrimary)

                    Text(alert.message)
                        .font(.system(size: Theme.fontSizeLabel))
                        .foregroundColor(Theme.textSecondary)

                    Spacer()

                    Text(formatDate(alert.timestamp))
                        .font(.system(size: Theme.fontSizeCaption))
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.vertical, Theme.paddingMicro)
            }
        }
        .padding(Theme.paddingMedium)
        .background(Theme.alertWarning.opacity(0.1))
        .cornerRadius(Theme.cornerRadiusSmall)
    }

    private var macGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: Theme.paddingMedium) {
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
        VStack(spacing: Theme.paddingMedium) {
            Text("Add Mac")
                .font(.system(size: Theme.fontSizeLarge, weight: .bold))
                .foregroundColor(Theme.textPrimary)

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
        .padding(Theme.paddingMedium)
        .frame(width: 350)
    }

    private func severityColor(_ severity: AlertSeverity) -> Color {
        switch severity {
        case .info: return Theme.alertInfo
        case .warning: return Theme.alertWarning
        case .critical: return Theme.alertCritical
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
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            HStack {
                Image(systemName: "desktopcomputer")
                    .font(.system(size: Theme.fontSizeTitle))
                    .foregroundColor(mac.isOnline ? Theme.statusGreen : Theme.textSecondary)

                VStack(alignment: .leading) {
                    Text(mac.name)
                        .font(.system(size: Theme.fontSizeBody, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                    Text(mac.isOnline ? "Online" : "Offline")
                        .font(.system(size: Theme.fontSizeCaption))
                        .foregroundColor(mac.isOnline ? Theme.statusGreen : Theme.textSecondary)
                }

                Spacer()

                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: Theme.fontSizeCaption))
                }
                .buttonStyle(.plain)
            }

            Divider()

            if let stats = mac.systemStats {
                VStack(spacing: Theme.paddingMicro) {
                    statRow("CPU", value: "\(Int(stats.cpuUsage))%", color: cpuColor(stats.cpuUsage))
                    statRow("Memory", value: "\(Int(stats.memoryUsage))%", color: memoryColor(stats.memoryUsage))
                    statRow("Disk", value: "\(Int(stats.diskUsage))%", color: diskColor(stats.diskUsage))
                    if stats.temperature > 0 {
                        statRow("Temp", value: "\(Int(stats.temperature))°C", color: tempColor(stats.temperature))
                    }
                }
            } else if mac.isOnline {
                Text("Loading stats...")
                    .font(.system(size: Theme.fontSizeCaption))
                    .foregroundColor(Theme.textSecondary)
            } else {
                Text("No data available")
                    .font(.system(size: Theme.fontSizeCaption))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(Theme.paddingSmall)
        .glassCard(cornerRadius: Theme.cornerRadius)
    }

    private func statRow(_ label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: Theme.fontSizeCaption))
                .foregroundColor(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: Theme.fontSizeCaption, weight: .medium))
                .foregroundColor(color)
        }
    }

    private func cpuColor(_ value: Double) -> Color {
        if value < 60 { return Theme.statusGreen }
        if value < 85 { return Theme.statusAmber }
        return Theme.statusRed
    }

    private func memoryColor(_ value: Double) -> Color {
        if value < 70 { return Theme.statusGreen }
        if value < 90 { return Theme.statusAmber }
        return Theme.statusRed
    }

    private func diskColor(_ value: Double) -> Color {
        if value < 80 { return Theme.statusGreen }
        if value < 95 { return Theme.statusAmber }
        return Theme.statusRed
    }

    private func tempColor(_ value: Double) -> Color {
        if value < 60 { return Theme.statusGreen }
        if value < 80 { return Theme.statusAmber }
        return Theme.statusRed
    }
}

// MARK: - Historical Reports View

struct HistoricalReportsView: View {
    @StateObject private var reportService = HistoricalReportService.shared
    @State private var selectedReportType: ReportType = .weekly

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.paddingMedium) {
                Text("Historical Reports")
                    .font(.system(size: Theme.fontSizeLarge, weight: .bold))
                    .foregroundColor(Theme.textPrimary)

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

                if !reportService.reports.isEmpty {
                    recentReportsSection
                }
            }
            .padding(Theme.paddingMedium)
        }
    }

    private var recentReportsSection: some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            Text("Recent Reports")
                .font(.system(size: Theme.fontSizeBody, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            ForEach(reportService.reports) { report in
                reportRow(report)
            }
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
                    .font(.system(size: Theme.fontSizeBody, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                Text("\(formatDate(report.startDate)) - \(formatDate(report.endDate))")
                    .font(.system(size: Theme.fontSizeCaption))
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("Avg CPU: \(Int(report.summary.avgCPU))%")
                    .font(.system(size: Theme.fontSizeCaption))
                    .foregroundColor(Theme.textPrimary)
                Text("\(report.anomalies.count) anomalies")
                    .font(.system(size: Theme.fontSizeCaption))
                    .foregroundColor(Theme.textSecondary)
            }

            Button("Export") {
                if let url = reportService.exportReportCSV(report) {
                    NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(Theme.paddingSmall)
        .glassCard(cornerRadius: Theme.cornerRadiusSmall)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
