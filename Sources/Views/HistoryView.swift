import SwiftUI
import Charts

struct HistoryView: View {
    @ObservedObject var viewModel: PulseViewModel
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @ScaledMetric var chartAxisFontSize: CGFloat = 11

    var body: some View {
        VStack(spacing: 0) {
            headerView

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

    private var headerView: some View {
        HStack {
            Text("History")
                .font(.system(size: Theme.fontSizeHeadline, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            Spacer()

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
                    .font(.system(size: Theme.fontSizeIcon))
                    .foregroundColor(Theme.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.paddingMedium)
    }

    // MARK: - CPU History Chart

    private var chartInterpolation: InterpolationMethod {
        reduceMotion ? .linear : .catmullRom
    }

    private var cpuHistoryChart: some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            Text("CPU History")
                .font(.system(size: Theme.fontSizeBody, weight: .semibold))
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
                        .interpolationMethod(chartInterpolation)

                        LineMark(
                            x: .value("Time", sample.timestamp),
                            y: .value("User", sample.cpuUser)
                        )
                        .foregroundStyle(Theme.cpuUser)
                        .interpolationMethod(chartInterpolation)

                        LineMark(
                            x: .value("Time", sample.timestamp),
                            y: .value("System", sample.cpuSystem)
                        )
                        .foregroundStyle(Theme.cpuSystem)
                        .interpolationMethod(chartInterpolation)
                    }
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))%")
                                    .font(.system(size: chartAxisFontSize))
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisValueLabel()
                            .font(.system(size: chartAxisFontSize))
                    }
                }
                .frame(height: 120)
            }
        }
        .padding(Theme.paddingMedium)
        .glassCard(cornerRadius: Theme.cornerRadius)
    }

    // MARK: - RAM History Chart

    private var ramHistoryChart: some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            Text("Memory History")
                .font(.system(size: Theme.fontSizeBody, weight: .semibold))
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
                                    .font(.system(size: chartAxisFontSize))
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisValueLabel()
                            .font(.system(size: chartAxisFontSize))
                    }
                }
                .frame(height: 100)
            }
        }
        .padding(Theme.paddingMedium)
        .glassCard(cornerRadius: Theme.cornerRadius)
    }

    // MARK: - Network History Chart

    private var networkHistoryChart: some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            Text("Network History")
                .font(.system(size: Theme.fontSizeBody, weight: .semibold))
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
                        .interpolationMethod(chartInterpolation)

                        LineMark(
                            x: .value("Time", sample.timestamp),
                            y: .value("Out", sample.networkOutDelta)
                        )
                        .foregroundStyle(Theme.networkUp)
                        .interpolationMethod(chartInterpolation)
                    }
                }
                .chartLegend(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(FormatUtils.formatSpeed(bytesPerSecond: v))
                                    .font(.system(size: chartAxisFontSize))
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisValueLabel()
                            .font(.system(size: chartAxisFontSize))
                    }
                }
                .frame(height: 100)
            }
        }
        .padding(Theme.paddingMedium)
        .glassCard(cornerRadius: Theme.cornerRadius)
    }

    private var emptyChartState: some View {
        VStack {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: Theme.fontSizeLarge))
                .foregroundColor(Theme.textSecondary)
            Text("Not enough data yet")
                .font(.system(size: Theme.fontSizeBody))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }
}
