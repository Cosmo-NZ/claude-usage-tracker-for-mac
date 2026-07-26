import XCTest
@testable import ClaudeUsageTracker

final class SubscriptionUsageClientTests: XCTestCase {
    private func fixture(_ name: String) throws -> Data {
        return try FixtureLoader.data(name)
    }

    func testParsesOrgID() throws {
        XCTAssertEqual(try SubscriptionUsageClient.parseOrgID(fixture("organizations")), "org-abc-123")
    }

    func testParsesUsageWindows() throws {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let result = try SubscriptionUsageClient.parseUsage(fixture("usage"), now: now)
        XCTAssertEqual(result.fiveHour?.utilization ?? 0, 0.42, accuracy: 0.0001)
        XCTAssertEqual(result.fiveHour?.windowLength, 5 * 3600)
        XCTAssertEqual(result.sevenDay?.utilization ?? 0, 0.63, accuracy: 0.0001)
        XCTAssertEqual(result.sevenDay?.windowLength, 7 * 24 * 3600)
        XCTAssertEqual(result.sevenDayOpus?.utilization ?? 0, 0.12, accuracy: 0.0001)
        // Real API returns microsecond fractional seconds + offset; tolerate the fraction.
        let expected = ISO8601DateFormatter().date(from: "2026-07-06T17:00:00Z")!
        XCTAssertEqual(result.fiveHour?.resetsAt.timeIntervalSince1970 ?? 0,
                       expected.timeIntervalSince1970, accuracy: 1.0)
    }

    func testParsesFableScopedWeeklyFromLimits() throws {
        let result = try SubscriptionUsageClient.parseUsage(fixture("usage"), now: Date())
        XCTAssertEqual(result.weeklyFable?.utilization ?? 0, 0.09, accuracy: 0.0001)
        XCTAssertEqual(result.weeklyFable?.windowLength, 7 * 24 * 3600)
    }

    func testFableAbsentWhenNoScopedLimit() throws {
        let json = Data(#"{"five_hour":{"utilization":10,"resets_at":"2026-07-06T17:00:00Z"}}"#.utf8)
        let result = try SubscriptionUsageClient.parseUsage(json, now: Date())
        XCTAssertNil(result.weeklyFable)
    }

    func testFableAtZeroPercentWithNullResetUsesWeeklyReset() throws {
        // Matches the real API when Fable usage is 0%: percent 0, resets_at null.
        let json = Data(#"""
        {
          "seven_day": { "utilization": 5, "resets_at": "2026-07-10T10:00:00.196449+00:00" },
          "limits": [
            { "kind": "weekly_scoped", "percent": 0, "resets_at": null,
              "scope": { "model": { "display_name": "Fable" } } }
          ]
        }
        """#.utf8)
        let result = try SubscriptionUsageClient.parseUsage(json, now: Date())
        XCTAssertNotNil(result.weeklyFable)
        XCTAssertEqual(result.weeklyFable?.utilization ?? -1, 0.0, accuracy: 0.0001)
        // Falls back to the overall weekly reset time.
        XCTAssertEqual(result.weeklyFable?.resetsAt, result.sevenDay?.resetsAt)
    }

    func testOpusAtZeroPercentWithNullResetUsesWeeklyReset() throws {
        // Matches the real API when Opus usage is 0%: utilization 0, resets_at null.
        let json = Data(#"""
        {
          "seven_day": { "utilization": 5, "resets_at": "2026-07-10T10:00:00.196449+00:00" },
          "seven_day_opus": { "utilization": 0, "resets_at": null }
        }
        """#.utf8)
        let result = try SubscriptionUsageClient.parseUsage(json, now: Date())
        XCTAssertNotNil(result.sevenDayOpus)
        XCTAssertEqual(result.sevenDayOpus?.utilization ?? -1, 0.0, accuracy: 0.0001)
        // Falls back to the overall weekly reset time.
        XCTAssertEqual(result.sevenDayOpus?.resetsAt, result.sevenDay?.resetsAt)
        XCTAssertEqual(result.sevenDayOpus?.windowLength, 7 * 24 * 3600)
    }

    func testParseDateHandlesFractionalSecondsAndOffset() {
        XCTAssertNotNil(SubscriptionUsageClient.parseDate("2026-07-06T03:00:00.249261+00:00"))
        XCTAssertNotNil(SubscriptionUsageClient.parseDate("2026-07-06T03:00:00.249+00:00"))
        XCTAssertNotNil(SubscriptionUsageClient.parseDate("2026-07-06T03:00:00Z"))
        XCTAssertNil(SubscriptionUsageClient.parseDate("garbage"))
    }

    func testMissingWindowsBecomeNil() throws {
        let result = try SubscriptionUsageClient.parseUsage(Data("{}".utf8), now: Date())
        XCTAssertNil(result.fiveHour)
        XCTAssertNil(result.sevenDay)
        XCTAssertNil(result.sevenDayOpus)
        XCTAssertNil(result.weeklyFable)
    }
}
