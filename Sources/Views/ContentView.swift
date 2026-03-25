import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: PulseViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
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
        .frame(width: 360, height: 420)
        .background(Theme.background)
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            Text("Pulse")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            Spacer()

            Button(action: { NSApplication.shared.terminate(nil) }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Theme.textSecondary)
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.paddingMedium)
        .padding(.vertical, Theme.paddingSmall)
        .background(Theme.surface)
    }

    // MARK: - CPU Section
    private var cpuSection: some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            Text("CPU")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)

            HStack(spacing: Theme.paddingMedium) {
                // Circular ring
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
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    legendRow(color: Theme.cpuUser, label: "User", value: String(format: "%.1f%%", viewModel.stats.cpuUser))
                    legendRow(color: Theme.cpuSystem, label: "System", value: String(format: "%.1f%%", viewModel.stats.cpuSystem))
                    legendRow(color: Theme.cpuIdle, label: "Idle", value: String(format: "%.1f%%", viewModel.stats.cpuIdle))
                }

                Spacer()
            }

            // Warning for high CPU
            if viewModel.stats.cpuTotal > 90 {
                warningBadge(text: "High CPU usage", color: Theme.statusRed)
            }
        }
        .padding(Theme.paddingMedium)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadius)
    }

    // MARK: - RAM Section
    private var ramSection: some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            HStack {
                Text("RAM")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Text(String(format: "%.0f%%", viewModel.stats.ramPercentage * 100))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.usageColor(for: viewModel.stats.ramPercentage))
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.surfaceLight)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.usageColor(for: viewModel.stats.ramPercentage))
                        .frame(width: geometry.size.width * CGFloat(viewModel.stats.ramPercentage), height: 8)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.stats.ramPercentage)
                }
            }
            .frame(height: 8)

            Text("\(formatBytes(viewModel.stats.ramUsed)) / \(formatBytes(viewModel.stats.ramTotal))")
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)

            if viewModel.stats.ramPercentage > 0.9 {
                warningBadge(text: "High memory usage", color: Theme.statusRed)
            }
        }
        .padding(Theme.paddingMedium)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadius)
    }

    // MARK: - Disk Section
    private var diskSection: some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            HStack {
                Text("SSD")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Text(String(format: "%.0f%%", viewModel.stats.diskPercentage * 100))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.usageColor(for: viewModel.stats.diskPercentage))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.surfaceLight)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.usageColor(for: viewModel.stats.diskPercentage))
                        .frame(width: geometry.size.width * CGFloat(min(viewModel.stats.diskPercentage, 1.0)), height: 8)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.stats.diskPercentage)
                }
            }
            .frame(height: 8)

            Text("\(formatBytes(viewModel.stats.diskUsed)) used of \(formatBytes(viewModel.stats.diskTotal))")
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)

            if viewModel.stats.diskPercentage > 0.9 {
                warningBadge(text: "Disk nearly full", color: Theme.statusRed)
            }
        }
        .padding(Theme.paddingMedium)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadius)
    }

    // MARK: - Network Section
    private var networkSection: some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            Text("Network")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)

            HStack(spacing: Theme.paddingLarge) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(Theme.networkUp)
                        .font(.system(size: 14))
                    Text(NetworkService.shared.formatSpeed(bytesPerSecond: viewModel.stats.networkOutDelta))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(Theme.networkDown)
                        .font(.system(size: 14))
                    Text(NetworkService.shared.formatSpeed(bytesPerSecond: viewModel.stats.networkInDelta))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                }

                Spacer()
            }
        }
        .padding(Theme.paddingMedium)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadius)
    }

    // MARK: - Helpers
    private func legendRow(color: Color, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(Theme.textPrimary)
        }
    }

    private func warningBadge(text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .cornerRadius(Theme.cornerRadiusSmall)
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let b = Double(bytes)
        if b >= 1_000_000_000_000 {
            return String(format: "%.1f TB", b / 1_000_000_000_000)
        } else if b >= 1_000_000_000 {
            return String(format: "%.0f GB", b / 1_000_000_000)
        } else if b >= 1_000_000 {
            return String(format: "%.0f MB", b / 1_000_000)
        } else {
            return String(format: "%.0f KB", b / 1_000)
        }
    }
}
