import SwiftUI

struct ProcessListView: View {
    @ObservedObject var viewModel: PulseViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Top Processes")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                Button(action: { viewModel.refreshProcesses() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.paddingMedium)

            Divider()

            if viewModel.topProcesses.isEmpty {
                VStack(spacing: Theme.paddingSmall) {
                    Spacer()
                    ProgressView()
                    Text("Loading processes...")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Header row
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
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .padding(.horizontal, Theme.paddingMedium)
                        .padding(.vertical, Theme.paddingSmall)

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
    }
}

struct ProcessRowView: View {
    let process: AppProcessInfo

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: Theme.paddingSmall) {
            // Process name
            Text(process.name)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
                .frame(width: 120, alignment: .leading)

            Spacer()

            // CPU
            Text(process.cpuString)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(cpuColor)
                .frame(width: 60, alignment: .trailing)

            // Memory
            Text(process.memoryString)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(Theme.textSecondary)
                .frame(width: 80, alignment: .trailing)

            // User
            Text(process.user)
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, Theme.paddingMedium)
        .padding(.vertical, 6)
        .background(isHovering ? Theme.surfaceLight : Color.clear)
        .onHover { hovering in isHovering = hovering }
    }

    private var cpuColor: Color {
        if process.cpuUsage > 80 { return Theme.statusRed }
        if process.cpuUsage > 50 { return Theme.statusAmber }
        return Theme.textPrimary
    }
}
