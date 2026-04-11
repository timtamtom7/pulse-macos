import XCTest
@testable import Pulse

final class FormatUtilsTests: XCTestCase {
    func testFormatBytesBytes() {
        let result = FormatUtils.formatBytes(500, precision: 0)
        XCTAssertEqual(result, "500 B")
    }

    func testFormatBytesKilobytes() {
        let result = FormatUtils.formatBytes(1_500, precision: 0)
        XCTAssertEqual(result, "1 KB")
    }

    func testFormatBytesMegabytes() {
        let result = FormatUtils.formatBytes(150_000_000, precision: 1)
        XCTAssertEqual(result, "143.0 MB")
    }

    func testFormatBytesGigabytes() {
        let result = FormatUtils.formatBytes(1_500_000_000, precision: 1)
        XCTAssertEqual(result, "1.4 GB")
    }

    func testFormatBytesTerabytes() {
        let result = FormatUtils.formatBytes(1_500_000_000_000, precision: 1)
        XCTAssertEqual(result, "1.4 TB")
    }

    func testFormatSpeedBytesPerSecond() {
        let result = FormatUtils.formatSpeed(bytesPerSecond: 500, precision: 0)
        XCTAssertEqual(result, "500 B/s")
    }

    func testFormatSpeedKilobytesPerSecond() {
        let result = FormatUtils.formatSpeed(bytesPerSecond: 1_500, precision: 1)
        XCTAssertEqual(result, "1.5 KB/s")
    }

    func testFormatSpeedMegabytesPerSecond() {
        let result = FormatUtils.formatSpeed(bytesPerSecond: 1_500_000, precision: 1)
        XCTAssertEqual(result, "1.4 MB/s")
    }

    func testFormatSpeedGigabytesPerSecond() {
        let result = FormatUtils.formatSpeed(bytesPerSecond: 1_500_000_000, precision: 1)
        XCTAssertEqual(result, "1.4 GB/s")
    }
}
