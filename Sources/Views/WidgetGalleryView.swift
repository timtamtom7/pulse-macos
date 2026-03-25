import SwiftUI

struct WidgetGalleryView: View {
    @ObservedObject var viewModel: PulseViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Widgets")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(12)

            Divider()

            ScrollView {
                VStack(spacing: 12) {
                    // Small Widget Preview
                    widgetPreview(
                        title: "Compact",
                        description: "CPU and RAM in a small frame",
                        icon: "rectangle.portrait",
                        preview: compactWidget
                    )

                    // Medium Widget Preview
                    widgetPreview(
                        title: "Standard",
                        description: "Full system overview",
                        icon: "rectangle",
                        preview: standardWidget
                    )

                    // Network Widget
                    widgetPreview(
                        title: "Network Focus",
                        description: "Download and upload speeds",
                        icon: "network",
                        preview: networkWidget
                    )
                }
                .padding(12)
            }
        }
        .frame(width: 400, height: 420)
        .background(Color(.windowBackgroundColor))
    }

    private func widgetPreview(title: String, description: String, icon: String, preview: some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            preview
                .frame(height: 80)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
        }
    }

    private var compactWidget: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("CPU")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                Text(String(format: "%.0f%%", viewModel.stats.cpuTotal))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                    Text("RAM")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                Text(String(format: "%.0f%%", viewModel.stats.ramPercentage))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding(12)
    }

    private var standardWidget: some View {
        HStack(spacing: 16) {
            // CPU
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("CPU")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                Text(String(format: "%.0f%%", viewModel.stats.cpuTotal))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }

            // RAM
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                    Text("RAM")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                Text(String(format: "%.0f%%", viewModel.stats.ramPercentage))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }

            // Disk
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    Text("Disk")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                Text(String(format: "%.0f%%", viewModel.stats.diskPercentage))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding(12)
    }

    private var networkWidget: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                    Text("Download")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                Text(formatBytesPerSecond(viewModel.stats.bandwidthIn))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                    Text("Upload")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                Text(formatBytesPerSecond(viewModel.stats.bandwidthOut))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding(12)
    }

    private func formatBytesPerSecond(_ bps: Double) -> String {
        let kbps = bps / 1024
        let mbps = kbps / 1024

        if mbps >= 1 {
            return String(format: "%.1f MB/s", mbps)
        } else if kbps >= 1 {
            return String(format: "%.0f KB/s", kbps)
        } else {
            return String(format: "%.0f B/s", bps)
        }
    }
}
