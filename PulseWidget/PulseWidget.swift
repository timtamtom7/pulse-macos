import WidgetKit
import SwiftUI

@main
struct PulseWidgetBundle: WidgetBundle {
    var body: some Widget {
        PulseSystemWidget()
        PulseNetworkWidget()
    }
}

struct PulseEntry: TimelineEntry {
    let date: Date
    let cpuPercent: Int
    let memoryPercent: Int
    let networkSpeed: String
    let macName: String
}

struct PulseProvider: TimelineProvider {
    func placeholder(in context: Context) -> PulseEntry {
        PulseEntry(date: Date(), cpuPercent: 45, memoryPercent: 62, networkSpeed: "12 MB/s ↓", macName: "Mac")
    }
    func getSnapshot(in context: Context, completion: @escaping (PulseEntry) -> Void) { completion(loadEntry()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<PulseEntry>) -> Void) {
        let entry = loadEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
    private func loadEntry() -> PulseEntry {
        let defaults = UserDefaults(suiteName: "group.com.pulse.macos") ?? .standard
        return PulseEntry(
            date: Date(),
            cpuPercent: defaults.integer(forKey: "widget_cpu"),
            memoryPercent: defaults.integer(forKey: "widget_memory"),
            networkSpeed: defaults.string(forKey: "widget_network") ?? "0 MB/s",
            macName: defaults.string(forKey: "widget_mac_name") ?? "Mac"
        )
    }
}

struct PulseSystemWidget: Widget {
    let kind = "PulseSystemWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PulseProvider()) { entry in
            SystemView(entry: entry)
        }
        .configurationDisplayName("System Monitor")
        .description("CPU and memory usage at a glance")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SystemView: View {
    let entry: PulseEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.green)
                Text("Pulse")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(entry.macName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            MetricRow(icon: "cpu", label: "CPU", value: "\(entry.cpuPercent)%", color: .blue)
            MetricRow(icon: "memorychip", label: "Memory", value: "\(entry.memoryPercent)%", color: .purple)
            
            Spacer()
        }
        .padding()
    }
}

struct MetricRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 16)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct PulseNetworkWidget: Widget {
    let kind = "PulseNetworkWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PulseProvider()) { entry in
            NetworkView(entry: entry)
        }
        .configurationDisplayName("Network")
        .description("Current network activity")
        .supportedFamilies([.systemSmall])
    }
}

struct NetworkView: View {
    let entry: PulseEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "network")
                    .foregroundColor(.orange)
                Text("Network")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "arrow.down.circle.fill")
                .font(.title)
                .foregroundColor(.green)
            Text(entry.networkSpeed)
                .font(.headline)
            Spacer()
        }
        .padding()
    }
}
