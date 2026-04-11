import SwiftUI

struct ProcessListView: View {
    @ObservedObject var viewModel: PulseViewModel

    var body: some View {
        VStack(spacing: 0) {
            headerView

            Divider()

            if viewModel.topProcesses.isEmpty {
                VStack(spacing: Theme.paddingSmall) {
                    Spacer()
                    ProgressView()
                    Text("Loading processes...")
                        .font(.system(size: Theme.fontSizeBody))
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        headerRow
                        Divider()

                        ForEach(viewModel.topProcesses) { process in
                            ProcessRowView(process: process)
                            Divider()
                                .padding(.leading, Theme.paddingMedium)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var headerView: some View {
        HStack {
            Text("Top Processes")
                .font(.system(size: Theme.fontSizeHeadline, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Button(action: { viewModel.refreshProcesses() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: Theme.fontSizeIcon))
                    .foregroundColor(Theme.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Refresh processes")
        }
        .padding(Theme.paddingMedium)
    }

    private var headerRow: some View {
        HStack(spacing: Theme.paddingSmall) {
            Text("PROCESS")
                .frame(width: 120, alignment: .leading)
            Text("CPU")
                .frame(width: 60, alignment: .trailing)
            Text("MEMORY")
                .frame(width: 80, alignment: .trailing)
            Text("USER")
                .frame(alignment: .trailing)
        }
        .font(.system(size: Theme.fontSizeCaption, weight: .semibold))
        .foregroundColor(Theme.textSecondary)
        .padding(.horizontal, Theme.paddingMedium)
        .padding(.vertical, Theme.paddingSmall)
    }
}

struct ProcessRowView: View {
    let process: AppProcessInfo

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: Theme.paddingSmall) {
            Text(process.name)
                .font(.system(size: Theme.fontSizeBody, weight: .medium, design: .monospaced))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
                .frame(width: 120, alignment: .leading)
                .accessibilityLabel(process.name)

            Spacer()

            Text(process.cpuString)
                .font(.system(size: Theme.fontSizeLabel, weight: .medium, design: .rounded))
                .foregroundColor(cpuColor)
                .frame(width: 60, alignment: .trailing)
                .accessibilityLabel("\(process.cpuString) CPU")

            Text(process.memoryString)
                .font(.system(size: Theme.fontSizeLabel, design: .monospaced))
                .foregroundColor(Theme.textSecondary)
                .frame(width: 80, alignment: .trailing)
                .accessibilityLabel(process.memoryString)

            Text(process.user)
                .font(.system(size: Theme.fontSizeLabel))
                .foregroundColor(Theme.textSecondary)
                .lineLimit(1)
                .accessibilityLabel("User \(process.user)")
        }
        .padding(.horizontal, Theme.paddingMedium)
        .padding(.vertical, Theme.paddingSmall)
        .background(isHovering ? Theme.surfaceLight : Color.clear)
        .onHover { hovering in isHovering = hovering }
        .accessibilityElement(children: .combine)
    }

    private var cpuColor: Color {
        if process.cpuUsage > 80 { return Theme.statusRed }
        if process.cpuUsage > 50 { return Theme.statusAmber }
        return Theme.textPrimary
    }
}
