import Foundation

struct PulseExport: Codable {
    let version: String
    let exportDate: Date
    let samples: [Sample]
}

final class ExportService {
    static let shared = ExportService()

    private init() {}

    func exportToJSON(samples: [Sample]) -> Data? {
        let export = PulseExport(
            version: "R9",
            exportDate: Date(),
            samples: samples
        )

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            return try encoder.encode(export)
        } catch {
            print("Failed to encode export: \(error)")
            return nil
        }
    }

    func exportToCSV(samples: [Sample]) -> String {
        var lines = ["timestamp,cpu_user,cpu_system,cpu_idle,ram_used_mb,ram_total_mb,ram_percent,disk_used_gb,disk_total_gb,disk_percent,network_in_delta,network_out_delta"]

        let dateFormatter = ISO8601DateFormatter()

        for sample in samples {
            let date = dateFormatter.string(from: sample.timestamp)
            let ramUsedMB = sample.ramUsed / (1024 * 1024)
            let ramTotalMB = sample.ramTotal / (1024 * 1024)
            let diskUsedGB = Double(sample.diskUsed) / (1024 * 1024 * 1024)
            let diskTotalGB = Double(sample.diskTotal) / (1024 * 1024 * 1024)

            let line = "\(date),\(sample.cpuUser),\(sample.cpuSystem),\(sample.cpuIdle),\(ramUsedMB),\(ramTotalMB),\(sample.ramPercentage),\(diskUsedGB),\(diskTotalGB),\(sample.diskPercentage),\(sample.networkInDelta),\(sample.networkOutDelta)"
            lines.append(line)
        }

        return lines.joined(separator: "\n")
    }

    func saveExportToFile(samples: [Sample], format: ExportFormat) -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: Date())

        let fileName: String
        let data: Data?

        switch format {
        case .json:
            fileName = "Pulse-Export-\(dateStr).json"
            data = exportToJSON(samples: samples)
        case .csv:
            fileName = "Pulse-Export-\(dateStr).csv"
            data = exportToCSV(samples: samples).data(using: .utf8)
        }

        guard let exportData = data else { return nil }

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            try exportData.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to write export file: \(error)")
            return nil
        }
    }
}

enum ExportFormat {
    case json
    case csv
}
