import XCTest
@testable import DevotionalCore

final class TimeAndGospelTests: XCTestCase {
    func testTimerSurvivesBackgroundAndPauseDoesNotConsumeTime() {
        let start = Date(timeIntervalSince1970: 1000)
        var timer = PracticeTimer(activityID: UUID(), seconds: 600, now: start)
        XCTAssertEqual(timer.remaining(at: start.addingTimeInterval(120)), 480)
        timer.pause(at: start.addingTimeInterval(120))
        XCTAssertEqual(timer.remaining(at: start.addingTimeInterval(900)), 480)
        timer.resume(at: start.addingTimeInterval(900))
        XCTAssertEqual(timer.remaining(at: start.addingTimeInterval(1000)), 380)
        XCTAssertEqual(timer.remaining(at: start.addingTimeInterval(2000)), 0)
    }
    func testTimerRoundTripPreservesDeadline() throws {
        let timer = PracticeTimer(activityID: UUID(), seconds: 600)
        XCTAssertEqual(try JSONDecoder().decode(PracticeTimer.self, from: JSONEncoder().encode(timer)), timer)
    }
    func testDefaultPlanHasNoEnabledReminder() {
        XCTAssertTrue(ReminderPlanner.build(Editorial.starterPlan()).requests.isEmpty)
    }
    func testReminderEditReplacesSameIDAndDisableRemovesRequest() {
        var state = Editorial.starterPlan()
        state.activities[0].reminder = Reminder(hour: 18)
        let before = ReminderPlanner.build(state).requests
        state.activities[0].reminder = Reminder(hour: 19)
        let after = ReminderPlanner.build(state).requests
        XCTAssertEqual(before.map(\.id), after.map(\.id))
        XCTAssertEqual(after[0].time.hour, 19)
        state.activities[0].isEnabled = false
        XCTAssertTrue(ReminderPlanner.build(state).requests.isEmpty)
    }
    func testSelectiveDaysAndCapacityAreExplicit() {
        var state = Editorial.starterPlan()
        state.activities[0].reminder = Reminder(hour: 12)
        state.activities[0].weekdays = [1, 3, 5]
        let plan = ReminderPlanner.build(state)
        XCTAssertEqual(plan.requests.compactMap(\.weekday), [1, 3, 5])
        let limited = ReminderPlanner.build(state, limit: 2)
        XCTAssertTrue(limited.requests.isEmpty)
        XCTAssertEqual(limited.omittedActivityIDs, [state.activities[0].id])
    }
    func testDeletingActivityClearsTimerOccurrencesAndReminder() {
        var state = Editorial.starterPlan(); let id = state.activities[0].id
        state.activities[0].reminder = Reminder(hour: 12)
        state.timer = PracticeTimer(activityID: id, seconds: 60)
        state.setCompleted(id, day: "2026-10-28", value: true)
        state.deleteActivity(id)
        XCTAssertNil(state.timer); XCTAssertTrue(state.occurrences.isEmpty)
        XCTAssertTrue(ReminderPlanner.build(state).requests.isEmpty)
    }
    func testGospelMustMatchRequestedLocalDay() throws {
        let c = fixture(day: "2026-11-01")
        XCTAssertNoThrow(try c.validate(for: "2026-11-01", edition: "test-only"))
        XCTAssertThrowsError(try c.validate(for: "2026-11-02", edition: "test-only"))
    }
    func testEmptyTextAndDifferentEditionAreRejected() {
        XCTAssertThrowsError(try fixture(day: "2026-11-01", text: " ").validate(for: "2026-11-01", edition: "test-only"))
        XCTAssertThrowsError(try fixture(day: "2026-11-01").validate(for: "2026-11-01", edition: "other"))
    }
    func testUnlicensedProviderIsNotContacted() async {
        let client = GospelClient(configuration: GospelConfiguration(endpoint: URL(string: "https://example.invalid/gospel")!, edition: "test", licenseConfirmed: false, audioAllowed: false, cacheAllowed: false))
        do { _ = try await client.fetch(day: "2026-11-01"); XCTFail("Should reject before networking") }
        catch { XCTAssertTrue(error is GospelError) }
    }
    func testMissingProviderIsExplicit() async {
        do { _ = try await GospelClient(configuration: nil).fetch(day: "2026-11-01"); XCTFail("Must be unavailable") }
        catch { XCTAssertTrue(error is GospelError) }
    }
    private func fixture(day: String, text: String = "Conteúdo artificial exclusivo para teste de contrato; não é passagem bíblica.") -> GospelContent {
        GospelContent(date: day, calendar: "roman-br", edition: "test-only", reference: "Referência de teste", text: text, sourceName: "Fixture", sourceURL: URL(string: "https://example.invalid")!)
    }
}
