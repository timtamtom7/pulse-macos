import XCTest
@testable import Pulse

final class SystemStatsTests: XCTestCase {
    func testSystemStatsZero() {
        let stats = SystemStats.zero
        XCTAssertEqual(stats.cpuUser, 0)
        XCTAssertEqual(stats.cpuSystem, 0)
        XCTAssertEqual(stats.cpuIdle, 100)
        XCTAssertEqual(stats.ramUsed, 0)
        XCTAssertEqual(stats.ramTotal, 0)
    }

    func testCpuTotalCalculation() {
        var stats = SystemStats()
        stats.cpuUser = 30.0
        stats.cpuSystem = 20.0
        XCTAssertEqual(stats.cpuTotal, 50.0)
    }

    func testRamPercentageCalculation() {
        var stats = SystemStats()
        stats.ramUsed = 8_000_000_000
        stats.ramTotal = 16_000_000_000
        XCTAssertEqual(stats.ramPercentage, 0.5, accuracy: 0.001)
    }

    func testRamPercentageWithZeroTotal() {
        var stats = SystemStats()
        stats.ramTotal = 0
        XCTAssertEqual(stats.ramPercentage, 0)
    }

    func testDiskPercentageCalculation() {
        var stats = SystemStats()
        stats.diskUsed = 400_000_000_000
        stats.diskTotal = 1_000_000_000_000
        XCTAssertEqual(stats.diskPercentage, 0.4, accuracy: 0.001)
    }

    func testDiskPercentageWithZeroTotal() {
        var stats = SystemStats()
        stats.diskTotal = 0
        XCTAssertEqual(stats.diskPercentage, 0)
    }
}
