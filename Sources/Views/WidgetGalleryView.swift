import SwiftUI

struct WidgetGalleryView: View {
    @ObservedObject var viewModel: PulseViewModel

    var body: some View {
        VStack(spacing: 0) {
            headerView

            Divider()

            ScrollView {
                VStack(spacing: Theme.paddingSmall) {
                    widgetPreview(
                        title: "Compact",
                        description: "CPU and RAM in a small frame",
                        icon: "rectangle.portrait",
                        preview: compactWidget
                    )

                    widgetPreview(
                        title: "Standard",
                        description: "Full system overview",
                        icon: "rectangle",
                        preview: standardWidget
                    )

                    widgetPreview(
                        title: "Network Focus",
                        description: "Download and upload speeds",
                        icon: "network",
                        preview: networkWidget
                    )
                }
                .padding(Theme.paddingMedium)
            }
        }
        .frame(width: 400, height: 420)
        .background(Theme.background)
    }

    private var headerView: some View {
        HStack {
            Text("Widgets")
                .font(.system(size: Theme.fontSizeTitle, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            Spacer()
        }
        .padding(Theme.paddingMedium)
    }

    private func widgetPreview(title: String, description: String, icon: String, preview: some View) -> some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: Theme.fontSizeIconLarge))
                    .foregroundColor(Theme.networkDown)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: Theme.fontSizeSubheadline, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    Text(description)
                        .font(.system(size: Theme.fontSizeLabel))
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
            }

            preview
                .frame(height: 80)
                .solidCard(cornerRadius: Theme.cornerRadiusSmall)
        }
    }

    private var compactWidget: some View {
        HStack(spacing: Theme.paddingSmall) {
            VStack(alignment: .leading, spacing: Theme.paddingMicro) {
                HStack(spacing: Theme.paddingMicro) {
                    Circle()
                        .fill(Theme.statusGreen)
                        .frame(width: 8, height: 8)
                    Text("CPU")
                        .font(.system(size: Theme.fontSizeCaption))
                        .foregroundColor(Theme.textSecondary)
                }
                Text(String(format: "%.0f%%", viewModel.stats.cpuTotal))
                    .font(.system(size: Theme.fontSizeLarge, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
            }

            VStack(alignment: .leading, spacing: Theme.paddingMicro) {
                HStack(spacing: Theme.paddingMicro) {
                    Circle()
                        .fill(Theme.networkDown)
                        .frame(width: 8, height: 8)
                    Text("RAM")
                        .font(.system(size: Theme.fontSizeCaption))
                        .foregroundColor(Theme.textSecondary)
                }
                Text(String(format: "%.0f%%", viewModel.stats.ramPercentage))
                    .font(.system(size: Theme.fontSizeLarge, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
            }

            Spacer()
        }
        .padding(Theme.paddingSmall)
    }

    private var standardWidget: some View {
        HStack(spacing: Theme.paddingMedium) {
            metricVStack(indicator: Theme.statusGreen, label: "CPU", value: String(format: "%.0f%%", viewModel.stats.cpuTotal))
            metricVStack(indicator: Theme.networkDown, label: "RAM", value: String(format: "%.0f%%", viewModel.stats.ramPercentage))
            metricVStack(indicator: Theme.statusAmber, label: "Disk", value: String(format: "%.0f%%", viewModel.stats.diskPercentage))
            Spacer()
        }
        .padding(Theme.paddingSmall)
    }

    private func metricVStack(indicator: Color, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.paddingMicro) {
            HStack(spacing: Theme.paddingMicro) {
                Circle()
                    .fill(indicator)
                    .frame(width: 8, height: 8)
                Text(label)
                    .font(.system(size: Theme.fontSizeCaption))
                    .foregroundColor(Theme.textSecondary)
            }
            Text(value)
                .font(.system(size: Theme.fontSizeBody, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
        }
    }

    private var networkWidget: some View {
        HStack(spacing: Theme.paddingMedium) {
            VStack(alignment: .leading, spacing: Theme.paddingMicro) {
                HStack(spacing: Theme.paddingMicro) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: Theme.fontSizeIcon))
                        .foregroundColor(Theme.statusGreen)
                    Text("Download")
                        .font(.system(size: Theme.fontSizeCaption))
                        .foregroundColor(Theme.textSecondary)
                }
                Text(FormatUtils.formatSpeed(bytesPerSecond: viewModel.stats.bandwidthIn))
                    .font(.system(size: Theme.fontSizeBody, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textPrimary)
            }

            VStack(alignment: .leading, spacing: Theme.paddingMicro) {
                HStack(spacing: Theme.paddingMicro) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: Theme.fontSizeIcon))
                        .foregroundColor(Theme.networkUp)
                    Text("Upload")
                        .font(.system(size: Theme.fontSizeCaption))
                        .foregroundColor(Theme.textSecondary)
                }
                Text(FormatUtils.formatSpeed(bytesPerSecond: viewModel.stats.bandwidthOut))
                    .font(.system(size: Theme.fontSizeBody, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textPrimary)
            }

            Spacer()
        }
        .padding(Theme.paddingSmall)
    }
}
