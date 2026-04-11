import XCTest
@testable import Pulse

final class AlertNotificationServiceTests: XCTestCase {
    var service: AlertNotificationService!

    override func setUp() {
        super.setUp()
        service = AlertNotificationService.shared
    }

    override func tearDown() {
        super.tearDown()
    }

    func testDefaultThresholds() {
        XCTAssertEqual(service.cpuWarnThreshold, AlertNotificationService.defaultCPUWarningThreshold)
        XCTAssertEqual(service.cpuCriticalThreshold, AlertNotificationService.defaultCPUCriticalThreshold)
        XCTAssertEqual(service.ramWarnThreshold, AlertNotificationService.defaultRAMWarningThreshold)
        XCTAssertEqual(service.ramCriticalThreshold, AlertNotificationService.defaultRAMCriticalThreshold)
    }

    func testCooldownInterval() {
        XCTAssertEqual(service.cooldownInterval, AlertNotificationService.notificationCooldownInterval)
        XCTAssertEqual(service.cooldownInterval, 300)
    }

    func testCheckStatsWithNormalCPU() {
        var stats = SystemStats()
        stats.cpuUser = 30.0
        stats.cpuSystem = 10.0
        stats.cpuIdle = 60.0
        stats.ramUsed = 8_000_000_000
        stats.ramTotal = 16_000_000_000

        service.checkStats(stats)
    }

    func testCheckStatsWithHighCPU() {
        var stats = SystemStats()
        stats.cpuUser = 80.0
        stats.cpuSystem = 20.0
        stats.cpuIdle = 0.0
        stats.ramUsed = 8_000_000_000
        stats.ramTotal = 16_000_000_000

        service.checkStats(stats)
    }

    func testCheckStatsWithCriticalCPU() {
        var stats = SystemStats()
        stats.cpuUser = 90.0
        stats.cpuSystem = 10.0
        stats.cpuIdle = 0.0
        stats.ramUsed = 16_000_000_000
        stats.ramTotal = 16_000_000_000

        service.checkStats(stats)
    }
}
