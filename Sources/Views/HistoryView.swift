import SwiftUI
import Charts

struct HistoryView: View {
    @ObservedObject var viewModel: PulseViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("History")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                // Time range picker
                Picker("", selection: $viewModel.historyHours) {
                    Text("1h").tag(1)
                    Text("6h").tag(6)
                    Text("12h").tag(12)
                    Text("24h").tag(24)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                .onChange(of: viewModel.historyHours) { _ in
                    viewModel.loadHistory()
                }

                Button(action: { viewModel.loadHistory() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.paddingMedium)

            Divider()

            ScrollView {
                VStack(spacing: Theme.paddingMedium) {
                    cpuHistoryChart
                    ramHistoryChart
                    networkHistoryChart
                }
                .padding(Theme.paddingMedium)
            }
        }
    }

    // MARK: - CPU History Chart

    private var cpuHistoryChart: some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            Text("CPU History")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)

            if viewModel.samples.isEmpty {
                emptyChartState
            } else {
                Chart {
                    ForEach(viewModel.samples) { sample in
                        AreaMark(
                            x: .value("Time", sample.timestamp),
                            y: .value("CPU", sample.cpuTotal)
                        )
                        .foregroundStyle(Theme.cpuSystem.opacity(0.4))
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Time", sample.timestamp),
                            y: .value("User", sample.cpuUser)
                        )
                        .foregroundStyle(Theme.cpuUser)
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Time", sample.timestamp),
                            y: .value("System", sample.cpuSystem)
                        )
                        .foregroundStyle(Theme.cpuSystem)
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))%")
                                    .font(.system(size: 9))
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisValueLabel()
                            .font(.system(size: 9))
                            
                    }
                }
                .frame(height: 120)
            }
        }
        .padding(Theme.paddingMedium)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadius)
    }

    // MARK: - RAM History Chart

    private var ramHistoryChart: some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            Text("Memory History")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)

            if viewModel.samples.isEmpty {
                emptyChartState
            } else {
                Chart {
                    ForEach(viewModel.samples) { sample in
                        AreaMark(
                            x: .value("Time", sample.timestamp),
                            y: .value("RAM", sample.ramPercentage * 100)
                        )
                        .foregroundStyle(Theme.cpuSystem.gradient)
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))%")
                                    .font(.system(size: 9))
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisValueLabel()
                            .font(.system(size: 9))
                            
                    }
                }
                .frame(height: 100)
            }
        }
        .padding(Theme.paddingMedium)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadius)
    }

    // MARK: - Network History Chart

    private var networkHistoryChart: some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            Text("Network History")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)

            if viewModel.samples.isEmpty {
                emptyChartState
            } else {
                Chart {
                    ForEach(viewModel.samples) { sample in
                        LineMark(
                            x: .value("Time", sample.timestamp),
                            y: .value("In", sample.networkInDelta)
                        )
                        .foregroundStyle(Theme.networkDown)
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Time", sample.timestamp),
                            y: .value("Out", sample.networkOutDelta)
                        )
                        .foregroundStyle(Theme.networkUp)
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(formatSpeed(v))
                                    .font(.system(size: 9))
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisValueLabel()
                            .font(.system(size: 9))
                            
                    }
                }
                .frame(height: 100)
            }
        }
        .padding(Theme.paddingMedium)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadius)
    }

    private var emptyChartState: some View {
        VStack {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 24))
                .foregroundColor(Theme.textSecondary)
            Text("Not enough data yet")
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }

    private func formatSpeed(_ bytesPerSec: Double) -> String {
        if bytesPerSec >= 1_000_000_000 {
            return String(format: "%.1f GB/s", bytesPerSec / 1_000_000_000)
        } else if bytesPerSec >= 1_000_000 {
            return String(format: "%.1f MB/s", bytesPerSec / 1_000_000)
        } else if bytesPerSec >= 1_000 {
            return String(format: "%.1f KB/s", bytesPerSec / 1_000)
        } else {
            return String(format: "%.0f B/s", bytesPerSec)
        }
    }
}
