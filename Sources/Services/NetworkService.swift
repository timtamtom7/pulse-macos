import Foundation

final class NetworkService {
    static let shared = NetworkService()

    private init() {}

    func formatSpeed(bytesPerSecond: UInt64) -> String {
        FormatUtils.formatSpeed(bytesPerSecond: Double(bytesPerSecond))
    }

    func formatBytes(_ bytes: UInt64) -> String {
        FormatUtils.formatBytes(bytes)
    }
}
