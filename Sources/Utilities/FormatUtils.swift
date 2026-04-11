import Foundation

enum FormatUnit: Double {
    case byte = 1_000
    case kilobyte = 1_000_000
    case megabyte = 1_000_000_000
    case gigabyte = 1_000_000_000_000
    case terabyte = 1_000_000_000_000_000

    var suffix: String {
        switch self {
        case .byte: return "B"
        case .kilobyte: return "KB"
        case .megabyte: return "MB"
        case .gigabyte: return "GB"
        case .terabyte: return "TB"
        }
    }
}

enum FormatSpeedUnit: Double {
    case bytePerSecond = 1_000
    case kilobytePerSecond = 1_000_000
    case megabytePerSecond = 1_000_000_000
    case gigabytePerSecond = 1_000_000_000_000

    var suffix: String {
        switch self {
        case .bytePerSecond: return "B/s"
        case .kilobytePerSecond: return "KB/s"
        case .megabytePerSecond: return "MB/s"
        case .gigabytePerSecond: return "GB/s"
        }
    }
}

struct FormatUtils {
    static func formatBytes(_ bytes: UInt64, precision: Int = 1) -> String {
        let b = Double(bytes)

        if b >= FormatUnit.terabyte.rawValue {
            return String(format: "%.\(precision)f TB", b / FormatUnit.terabyte.rawValue)
        } else if b >= FormatUnit.gigabyte.rawValue {
            return String(format: "%.\(precision)f GB", b / FormatUnit.gigabyte.rawValue)
        } else if b >= FormatUnit.megabyte.rawValue {
            return String(format: "%.\(precision)f MB", b / FormatUnit.megabyte.rawValue)
        } else if b >= FormatUnit.kilobyte.rawValue {
            return String(format: "%.\(precision)f KB", b / FormatUnit.kilobyte.rawValue)
        } else {
            return String(format: "%.0f B", b)
        }
    }

    static func formatSpeed(bytesPerSecond: Double, precision: Int = 1) -> String {
        if bytesPerSecond >= FormatSpeedUnit.gigabytePerSecond.rawValue {
            return String(format: "%.\(precision)f GB/s", bytesPerSecond / FormatSpeedUnit.gigabytePerSecond.rawValue)
        } else if bytesPerSecond >= FormatSpeedUnit.megabytePerSecond.rawValue {
            return String(format: "%.\(precision)f MB/s", bytesPerSecond / FormatSpeedUnit.megabytePerSecond.rawValue)
        } else if bytesPerSecond >= FormatSpeedUnit.kilobytePerSecond.rawValue {
            return String(format: "%.\(precision)f KB/s", bytesPerSecond / FormatSpeedUnit.kilobytePerSecond.rawValue)
        } else {
            return String(format: "%.0f B/s", bytesPerSecond)
        }
    }

    static func formatBytesDecimal(_ bytes: UInt64, precision: Int = 1) -> String {
        let b = Double(bytes)

        if b >= 1_000_000_000_000 {
            return String(format: "%.\(precision)f TB", b / 1_000_000_000_000)
        } else if b >= 1_000_000_000 {
            return String(format: "%.\(precision)f GB", b / 1_000_000_000)
        } else if b >= 1_000_000 {
            return String(format: "%.\(precision)f MB", b / 1_000_000)
        } else if b >= 1_000 {
            return String(format: "%.\(precision)f KB", b / 1_000)
        } else {
            return String(format: "%.0f B", b)
        }
    }
}

enum PulseError: Error, LocalizedError {
    case databaseConnectionFailed
    case databaseQueryFailed(String)
    case networkRequestFailed(String)
    case invalidData
    case timeout
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .databaseConnectionFailed:
            return "Failed to connect to database"
        case .databaseQueryFailed(let message):
            return "Database query failed: \(message)"
        case .networkRequestFailed(let message):
            return "Network request failed: \(message)"
        case .invalidData:
            return "Invalid data received"
        case .timeout:
            return "Request timed out"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
}
