import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: PulseViewModel

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            OverviewTabView(viewModel: viewModel)
                .tabItem {
                    Label("Overview", systemImage: "gauge")
                }
                .tag(0)

            NetworkTabView(viewModel: viewModel)
                .tabItem {
                    Label("Network", systemImage: "network")
                }
                .tag(1)

            HistoryView(viewModel: viewModel)
                .tabItem {
                    Label("History", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)

            ProcessListView(viewModel: viewModel)
                .tabItem {
                    Label("Processes", systemImage: "list.bullet")
                }
                .tag(3)

            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "rectangle.grid.1x2")
                }
                .tag(4)

            HistoricalReportsView()
                .tabItem {
                    Label("Reports", systemImage: "doc.text")
                }
                .tag(5)

            WidgetGalleryView(viewModel: viewModel)
                .tabItem {
                    Label("Widgets", systemImage: "square.grid.2x2")
                }
                .tag(6)

            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(7)
        }
        .frame(width: 380, height: 420)
        .background(Theme.background)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Network Tab

struct NetworkTabView: View {
    @ObservedObject var viewModel: PulseViewModel

    var body: some View {
        VStack(spacing: 0) {
            headerView

            Divider()

            ScrollView {
                VStack(spacing: Theme.paddingSmall) {
                    HStack(spacing: Theme.paddingSmall) {
                        networkCard(
                            title: "Downloaded",
                            value: FormatUtils.formatBytes(viewModel.stats.networkInDelta),
                            icon: "arrow.down.circle.fill",
                            color: Theme.networkDown
                        )

                        networkCard(
                            title: "Uploaded",
                            value: FormatUtils.formatBytes(viewModel.stats.networkOutDelta),
                            icon: "arrow.up.circle.fill",
                            color: Theme.networkUp
                        )
                    }

                    speedSection
                }
                .padding(Theme.paddingMedium)
            }
        }
    }

    private var headerView: some View {
        HStack {
            Text("Network")
                .font(.system(size: Theme.fontSizeTitle, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            Spacer()
        }
        .padding(Theme.paddingMedium)
    }

    private func networkCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: Theme.paddingMicro) {
            HStack(spacing: Theme.paddingMicro) {
                Image(systemName: icon)
                    .font(.system(size: Theme.fontSizeIcon))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: Theme.fontSizeLabel))
                    .foregroundColor(Theme.textSecondary)
            }

            Text(value)
                .font(.system(size: Theme.fontSizeLarge, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.paddingSmall)
        .solidCard(cornerRadius: Theme.cornerRadiusSmall)
    }

    private var speedSection: some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            Text("Current Speed")
                .font(.system(size: Theme.fontSizeBody, weight: .medium))
                .foregroundColor(Theme.textSecondary)

            VStack(spacing: Theme.paddingSmall) {
                speedRow(label: "Download", value: FormatUtils.formatSpeed(bytesPerSecond: viewModel.stats.bandwidthIn), color: Theme.networkDown)
                speedRow(label: "Upload", value: FormatUtils.formatSpeed(bytesPerSecond: viewModel.stats.bandwidthOut), color: Theme.networkUp)
            }
            .padding(Theme.paddingSmall)
            .solidCard(cornerRadius: Theme.cornerRadiusSmall)
        }
    }

    private func speedRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: Theme.fontSizeBody))
                .foregroundColor(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: Theme.fontSizeBody, weight: .medium, design: .monospaced))
                .foregroundColor(Theme.textPrimary)
        }
    }
}

// MARK: - Overview Tab

struct OverviewTabView: View {
    @ObservedObject var viewModel: PulseViewModel

    var body: some View {
        VStack(spacing: 0) {
            headerView

            ScrollView {
                VStack(spacing: Theme.paddingMedium) {
                    cpuSection
                    ramSection
                    diskSection
                    networkSection
                }
                .padding(Theme.paddingMedium)
            }
        }
    }

    private var headerView: some View {
        HStack {
            Text("Pulse")
                .font(.system(size: Theme.fontSizeLarge, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            Spacer()

            Button(action: { NSApplication.shared.terminate(nil) }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Theme.textSecondary)
                    .font(.system(size: Theme.fontSizeIconLarge))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close Pulse")
        }
        .padding(.horizontal, Theme.paddingMedium)
        .padding(.vertical, Theme.paddingSmall)
        .glassCard(cornerRadius: Theme.cornerRadius)
    }

    // MARK: - CPU Section
    private var cpuSection: some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            Text("CPU")
                .font(.system(size: Theme.fontSizeBody, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .accessibilityLabel("CPU usage")

            HStack(spacing: Theme.paddingMedium) {
                ZStack {
                    Circle()
                        .stroke(Theme.cpuIdle, lineWidth: 6)
                        .frame(width: 64, height: 64)

                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.stats.cpuTotal / 100))
                        .stroke(
                            AngularGradient(
                                colors: [Theme.cpuUser, Theme.cpuSystem],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))

                    Text(String(format: "%.0f%%", viewModel.stats.cpuTotal))
                        .font(.system(size: Theme.fontSizeHeadline, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                }

                VStack(alignment: .leading, spacing: Theme.paddingMicro) {
                    legendRow(color: Theme.cpuUser, label: "User", value: String(format: "%.1f%%", viewModel.stats.cpuUser))
                    legendRow(color: Theme.cpuSystem, label: "System", value: String(format: "%.1f%%", viewModel.stats.cpuSystem))
                    legendRow(color: Theme.cpuIdle, label: "Idle", value: String(format: "%.1f%%", viewModel.stats.cpuIdle))
                }

                Spacer()
            }

            if viewModel.stats.cpuTotal > 90 {
                warningBadge(text: "High CPU usage", color: Theme.statusRed)
            }
        }
        .padding(Theme.paddingMedium)
        .glassCard(cornerRadius: Theme.cornerRadius)
        .accessibilityElement(children: .contain)
    }

    // MARK: - RAM Section
    private var ramSection: some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            HStack {
                Text("RAM")
                    .font(.system(size: Theme.fontSizeBody, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .accessibilityLabel("Memory usage")
                Spacer()
                Text(String(format: "%.0f%%", viewModel.stats.ramPercentage * 100))
                    .font(.system(size: Theme.fontSizeBody, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.usageColor(for: viewModel.stats.ramPercentage))
                    .accessibilityLabel("\(Int(viewModel.stats.ramPercentage * 100)) percent memory used")
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.surfaceLight)
                        .frame(height: 8)

                    Capsule()
                        .fill(Theme.usageColor(for: viewModel.stats.ramPercentage))
                        .frame(width: max(0, geometry.size.width * CGFloat(viewModel.stats.ramPercentage)), height: 8)
                        .animation(Theme.springAnimation, value: viewModel.stats.ramPercentage)
                }
            }
            .frame(height: 8)

            Text("\(FormatUtils.formatBytes(viewModel.stats.ramUsed, precision: 0)) / \(FormatUtils.formatBytes(viewModel.stats.ramTotal, precision: 0))")
                .font(.system(size: Theme.fontSizeLabel))
                .foregroundColor(Theme.textSecondary)

            if viewModel.stats.ramPercentage > 0.9 {
                warningBadge(text: "High memory usage", color: Theme.statusRed)
            }
        }
        .padding(Theme.paddingMedium)
        .glassCard(cornerRadius: Theme.cornerRadius)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Disk Section
    private var diskSection: some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            HStack {
                Text("SSD")
                    .font(.system(size: Theme.fontSizeBody, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .accessibilityLabel("Disk usage")
                Spacer()
                Text(String(format: "%.0f%%", viewModel.stats.diskPercentage * 100))
                    .font(.system(size: Theme.fontSizeBody, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.usageColor(for: viewModel.stats.diskPercentage))
                    .accessibilityLabel("\(Int(viewModel.stats.diskPercentage * 100)) percent disk used")
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.surfaceLight)
                        .frame(height: 8)

                    Capsule()
                        .fill(Theme.usageColor(for: viewModel.stats.diskPercentage))
                        .frame(width: max(0, geometry.size.width * CGFloat(min(viewModel.stats.diskPercentage, 1.0))), height: 8)
                        .animation(Theme.springAnimation, value: viewModel.stats.diskPercentage)
                }
            }
            .frame(height: 8)

            Text("\(FormatUtils.formatBytes(viewModel.stats.diskUsed, precision: 0)) used of \(FormatUtils.formatBytes(viewModel.stats.diskTotal, precision: 0))")
                .font(.system(size: Theme.fontSizeLabel))
                .foregroundColor(Theme.textSecondary)

            if viewModel.stats.diskPercentage > 0.9 {
                warningBadge(text: "Disk nearly full", color: Theme.statusRed)
            }
        }
        .padding(Theme.paddingMedium)
        .glassCard(cornerRadius: Theme.cornerRadius)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Network Section
    private var networkSection: some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            Text("Network")
                .font(.system(size: Theme.fontSizeBody, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .accessibilityLabel("Network activity")

            HStack(spacing: Theme.paddingLarge) {
                HStack(spacing: Theme.paddingMicro) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(Theme.networkUp)
                        .font(.system(size: Theme.fontSizeIconLarge))
                        .accessibilityLabel("Upload")
                    Text(NetworkService.shared.formatSpeed(bytesPerSecond: viewModel.stats.networkOutDelta))
                        .font(.system(size: Theme.fontSizeBody, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                }

                HStack(spacing: Theme.paddingMicro) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(Theme.networkDown)
                        .font(.system(size: Theme.fontSizeIconLarge))
                        .accessibilityLabel("Download")
                    Text(NetworkService.shared.formatSpeed(bytesPerSecond: viewModel.stats.networkInDelta))
                        .font(.system(size: Theme.fontSizeBody, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                }

                Spacer()
            }
        }
        .padding(Theme.paddingMedium)
        .glassCard(cornerRadius: Theme.cornerRadius)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Helpers
    private func legendRow(color: Color, label: String, value: String) -> some View {
        HStack(spacing: Theme.paddingMicro) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: Theme.fontSizeLabel))
                .foregroundColor(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: Theme.fontSizeLabel, design: .rounded))
                .foregroundColor(Theme.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }

    private func warningBadge(text: String, color: Color) -> some View {
        HStack(spacing: Theme.paddingMicro) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: Theme.fontSizeCaption))
            Text(text)
                .font(.system(size: Theme.fontSizeCaption, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, Theme.paddingSmall)
        .padding(.vertical, Theme.paddingMicro)
        .background(color.opacity(0.15))
        .cornerRadius(Theme.cornerRadiusSmall)
        .accessibilityLabel("Warning: \(text)")
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var viewModel: PulseViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.paddingMedium) {
                dataSection
                aboutSection
            }
            .padding(Theme.paddingMedium)
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            Text("DATA")
                .font(.system(size: Theme.fontSizeLabel, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: Theme.paddingSmall) {
                Button(action: exportData) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Data as CSV")
                    }
                    .font(.system(size: Theme.fontSizeBody, weight: .medium))
                    .foregroundColor(Theme.networkDown)
                }
                .buttonStyle(.plain)

                Text("Export all recorded samples for external analysis")
                    .font(.system(size: Theme.fontSizeLabel))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(Theme.paddingSmall)
            .glassCard(cornerRadius: Theme.cornerRadiusSmall)
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            Text("ABOUT")
                .font(.system(size: Theme.fontSizeLabel, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: Theme.paddingMicro) {
                Text("Pulse")
                    .font(.system(size: Theme.fontSizeSubheadline, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                Text("System monitor for macOS")
                    .font(.system(size: Theme.fontSizeLabel))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(Theme.paddingSmall)
            .glassCard(cornerRadius: Theme.cornerRadiusSmall)
        }
    }

    private func exportData() {
        if let url = viewModel.exportCSV() {
            NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
        }
    }
}
