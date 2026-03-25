import Foundation

final class NetworkService {
    static let shared = NetworkService()

    private init() {}

    func formatSpeed(bytesPerSecond: UInt64) -> String {
        let bytes = Double(bytesPerSecond)

        if bytes >= 1_000_000_000 {
            return String(format: "%.1f GB/s", bytes / 1_000_000_000)
        } else if bytes >= 1_000_000 {
            return String(format: "%.1f MB/s", bytes / 1_000_000)
        } else if bytes >= 1_000 {
            return String(format: "%.1f KB/s", bytes / 1_000)
        } else {
            return String(format: "%.0f B/s", bytes)
        }
    }

    func formatBytes(_ bytes: UInt64) -> String {
        let b = Double(bytes)

        if b >= 1_000_000_000 {
            return String(format: "%.1f GB", b / 1_000_000_000)
        } else if b >= 1_000_000 {
            return String(format: "%.1f MB", b / 1_000_000)
        } else if b >= 1_000 {
            return String(format: "%.1f KB", b / 1_000)
        } else {
            return String(format: "%.0f B", b)
        }
    }
}
