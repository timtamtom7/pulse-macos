import Foundation

final class DiskService {
    static let shared = DiskService()

    private init() {}

    func formatBytes(_ bytes: UInt64) -> String {
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

    func getDiskInfo() -> (used: UInt64, total: UInt64) {
        do {
            let attrs = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            let total = (attrs[.systemSize] as? UInt64) ?? 0
            let free = (attrs[.systemFreeSize] as? UInt64) ?? 0
            let used = total - free
            return (used, total)
        } catch {
            return (0, 0)
        }
    }
}
