import Foundation
import IOKit.ps

struct BatteryInfo {
    let isPresent: Bool
    let percentage: Int
    let isCharging: Bool
    let timeRemaining: Int? // minutes, nil if calculating

    static let unavailable = BatteryInfo(isPresent: false, percentage: 0, isCharging: false, timeRemaining: nil)
}

final class BatteryService {
    static let shared = BatteryService()

    private init() {}

    func getBatteryInfo() -> BatteryInfo {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              !sources.isEmpty else {
            return .unavailable
        }

        for source in sources {
            guard let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }

            let isPresent = info[kIOPSIsPresentKey as String] as? Bool ?? false
            guard isPresent else { continue }

            let percentage = info[kIOPSCurrentCapacityKey as String] as? Int ?? 0
            let isCharging = info[kIOPSIsChargingKey as String] as? Bool ?? false

            var timeRemaining: Int? = nil
            if let time = info[kIOPSTimeToEmptyKey as String] as? Int, time >= 0 {
                timeRemaining = time
            } else if let time = info[kIOPSTimeToFullChargeKey as String] as? Int, time >= 0 {
                timeRemaining = time
            }

            return BatteryInfo(isPresent: true, percentage: percentage, isCharging: isCharging, timeRemaining: timeRemaining)
        }

        return .unavailable
    }
}
