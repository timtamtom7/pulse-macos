import Foundation

final class DiskService {
    static let shared = DiskService()

    private init() {}

    func formatBytes(_ bytes: UInt64) -> String {
        FormatUtils.formatBytes(bytes, precision: 0)
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
