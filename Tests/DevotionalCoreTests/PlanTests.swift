import XCTest
@testable import DevotionalCore

final class PlanTests: XCTestCase {
    func testMovingActivityPreservesIdentityQuestionsNotesAndReminder() throws {
        var state = Editorial.starterPlan()
        var exam = state.activities.last!
        exam.reminder = Reminder(hour: 19)
        state.upsert(exam)
        state.notes = [PersonalNote(activityID: exam.id, day: "2026-10-28", text: "Minha nota")]
        state.moveActivity(exam.id, to: state.moments[0].id, index: 0)
        XCTAssertEqual(state.orderedActivities(in: state.moments[0].id).first?.id, exam.id)
        XCTAssertEqual(state.activity(exam.id)?.questions, exam.questions)
        XCTAssertEqual(state.activity(exam.id)?.reminder, Reminder(hour: 19))
        XCTAssertEqual(state.notes.first?.activityID, exam.id)
        try state.validate()
    }
    func testOccurrenceIsIdempotentAndDoesNotLeakIntoNextDay() {
        var state = Editorial.starterPlan(); let id = state.activities[0].id
        state.setCompleted(id, day: "2026-10-28", value: true)
        state.setCompleted(id, day: "2026-10-28", value: true)
        XCTAssertEqual(state.occurrences.count, 1)
        XCTAssertFalse(state.completed(id, on: "2026-10-29"))
        state.setCompleted(id, day: "2026-10-28", value: false)
        XCTAssertTrue(state.occurrences.isEmpty)
    }
    func testSundayOnlyAndDisabledActivity() {
        var a = Editorial.starterPlan().activities[0]
        a.weekdays = [1]
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let sunday = calendar.date(from: DateComponents(year: 2026, month: 10, day: 25))!
        XCTAssertTrue(a.isScheduled(on: sunday, calendar: calendar))
        XCTAssertFalse(a.isScheduled(on: sunday.addingTimeInterval(86400), calendar: calendar))
        a.isEnabled = false
        XCTAssertFalse(a.isScheduled(on: sunday, calendar: calendar))
    }
    func testLocalDateUsesBrasiliaNotUTC() {
        let date = ISO8601DateFormatter().date(from: "2026-10-29T01:30:00Z")!
        XCTAssertEqual(LocalDay.string(date, timeZone: TimeZone(identifier: "America/Sao_Paulo")!), "2026-10-28")
        XCTAssertEqual(LocalDay.string(date, timeZone: TimeZone(secondsFromGMT: 0)!), "2026-10-29")
    }
    func testMoveMomentAndMoveBlocksSurvivePersistence() throws {
        var state = Editorial.starterPlan()
        let added = Moment(name: "Ao sair do trabalho"); state.moments.append(added)
        for a in Array(state.activities.prefix(2)) { state.moveActivity(a.id, to: added.id, index: 0) }
        state.moveMoment(added.id, to: 0)
        let repo = repository()
        defer { try? FileManager.default.removeItem(at: repo.fileURL.deletingLastPathComponent()) }
        try repo.save(state)
        XCTAssertEqual(try repo.load(), state)
    }
    func testMovingMomentContentsKeepsNotesAndDeletingRemovesThem() throws {
        var state = Editorial.starterPlan()
        let exam = state.activities.last!, source = state.moments.last!.id, target = state.moments[0].id
        state.notes = [PersonalNote(activityID: exam.id, day: "2026-10-28", text: "Nota")]
        try state.deleteMoment(source, movingTo: target)
        XCTAssertEqual(state.activity(exam.id)?.momentID, target)
        XCTAssertEqual(state.notes.count, 1)
        state.deleteActivity(exam.id)
        XCTAssertTrue(state.notes.isEmpty)
        try state.validate()
    }
    func testInvalidMoveTargetDoesNotMutateData() throws {
        var state = Editorial.starterPlan(); let before = state
        XCTAssertThrowsError(try state.deleteMoment(state.moments[0].id, movingTo: UUID()))
        XCTAssertEqual(state, before)
    }
    func testEditingTemplateCopyDoesNotChangeOtherBlocks() {
        var first = Editorial.examinations[0].copyQuestions()
        let second = Editorial.examinations[0].copyQuestions()
        first[0].text = "Uma pergunta pessoal"
        XCTAssertNotEqual(first[0].text, second[0].text)
        XCTAssertNotEqual(first[0].id, second[0].id)
        XCTAssertEqual(second[0].text, Editorial.examinations[0].questions[0])
    }
    func testRecurrenceEditDoesNotRewriteHistory() {
        var state = Editorial.starterPlan(); var a = state.activities[0]
        state.setCompleted(a.id, day: "2026-10-28", value: true)
        a.weekdays = [1]; state.upsert(a)
        XCTAssertTrue(state.completed(a.id, on: "2026-10-28"))
    }
    func testNotesEditAndDeletePersist() throws {
        var state = Editorial.starterPlan(); let repo = repository()
        defer { try? FileManager.default.removeItem(at: repo.fileURL.deletingLastPathComponent()) }
        let note = PersonalNote(activityID: state.activities[0].id, day: "2026-10-28", text: "Primeiro texto")
        state.notes.append(note); try repo.save(state)
        state = try repo.load(); state.notes[0].text = "Texto corrigido"; try repo.save(state)
        XCTAssertEqual(try repo.load().notes[0].text, "Texto corrigido")
        state.notes.removeAll(); try repo.save(state)
        XCTAssertTrue(try repo.load().notes.isEmpty)
    }
    func testCorruptStoreIsNotOverwrittenOnLoad() throws {
        let repo = repository()
        defer { try? FileManager.default.removeItem(at: repo.fileURL.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: repo.fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = Data("invalid-json".utf8); try data.write(to: repo.fileURL)
        XCTAssertThrowsError(try repo.load())
        XCTAssertEqual(try Data(contentsOf: repo.fileURL), data)
    }
    func testFutureSchemaIsRejected() throws {
        let repo = repository()
        defer { try? FileManager.default.removeItem(at: repo.fileURL.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: repo.fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("{\"schemaVersion\":99}".utf8).write(to: repo.fileURL)
        XCTAssertThrowsError(try repo.load())
    }
    func testDuplicateOccurrenceRejectedAndInvalidSavePreservesLastState() throws {
        let repo = repository(); var state = Editorial.starterPlan()
        defer { try? FileManager.default.removeItem(at: repo.fileURL.deletingLastPathComponent()) }
        try repo.save(state); let original = state
        let o = Occurrence(activityID: state.activities[0].id, day: "2026-10-28", completedAt: Date())
        state.occurrences = [o, o]
        XCTAssertThrowsError(try repo.save(state)); XCTAssertEqual(try repo.load(), original)
    }
    private func repository() -> PlanRepository {
        PlanRepository(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("plan.json"))
    }
}
