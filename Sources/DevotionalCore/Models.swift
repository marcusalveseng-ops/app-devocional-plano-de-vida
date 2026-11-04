import Foundation

public enum ActivityKind: String, Codable, CaseIterable, Identifiable {
    case devotion, mentalPrayer, spiritualReading, gospel, examination, free
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .devotion: return "Oração e devoção"
        case .mentalPrayer: return "Oração mental"
        case .spiritualReading: return "Leitura espiritual"
        case .gospel: return "Evangelho do dia"
        case .examination: return "Exame de consciência"
        case .free: return "Prática livre"
        }
    }
    public var symbol: String {
        switch self {
        case .devotion: return "sun.max"
        case .mentalPrayer: return "leaf"
        case .spiritualReading: return "book.closed"
        case .gospel: return "book"
        case .examination: return "moon.stars"
        case .free: return "heart"
        }
    }
    public var supportsTimer: Bool { self == .devotion || self == .mentalPrayer || self == .spiritualReading }
}

public struct Reminder: Codable, Equatable {
    public var hour: Int
    public var minute: Int
    public init(hour: Int, minute: Int = 0) { self.hour = hour; self.minute = minute }
    public var display: String { String(format: "%02d:%02d", hour, minute) }
    public var isValid: Bool { (0...23).contains(hour) && (0...59).contains(minute) }
}

public struct Question: Codable, Equatable, Identifiable {
    public var id: UUID
    public var text: String
    public init(id: UUID = UUID(), text: String) { self.id = id; self.text = text }
}

public struct Activity: Codable, Equatable, Identifiable {
    public var id: UUID
    public var name: String
    public var kind: ActivityKind
    public var momentID: UUID
    public var position: Int
    public var isEnabled = true
    /// Calendar weekday: Sunday = 1, Saturday = 7.
    public var weekdays: Set<Int> = Set(1...7)
    public var durationMinutes: Int?
    public var reminder: Reminder?
    public var supportText = ""
    public var bookTitle = ""
    public var intention = ""
    public var questions: [Question] = []
    public init(id: UUID = UUID(), name: String, kind: ActivityKind, momentID: UUID, position: Int = 0) {
        self.id = id; self.name = name; self.kind = kind; self.momentID = momentID; self.position = position
        if kind.supportsTimer { durationMinutes = 10 }
    }
    public func isScheduled(on date: Date, calendar: Calendar = .current) -> Bool {
        isEnabled && weekdays.contains(calendar.component(.weekday, from: date))
    }
}

public struct Moment: Codable, Equatable, Identifiable {
    public var id: UUID
    public var name: String
    public init(id: UUID = UUID(), name: String) { self.id = id; self.name = name }
}

public struct Occurrence: Codable, Equatable, Identifiable {
    public var activityID: UUID
    public var day: String
    public var completedAt: Date
    public var id: String { Self.key(activityID, day) }
    public static func key(_ activityID: UUID, _ day: String) -> String { "\(activityID.uuidString)/\(day)" }
    public init(activityID: UUID, day: String, completedAt: Date) {
        self.activityID = activityID; self.day = day; self.completedAt = completedAt
    }
}

public struct PersonalNote: Codable, Equatable, Identifiable {
    public var id: UUID
    public var activityID: UUID
    public var day: String
    public var createdAt: Date
    public var modifiedAt: Date
    public var text: String
    public init(id: UUID = UUID(), activityID: UUID, day: String, text: String, now: Date = Date()) {
        self.id = id; self.activityID = activityID; self.day = day; self.text = text
        createdAt = now; modifiedAt = now
    }
}

public struct Preferences: Codable, Equatable {
    public var voiceID: String?
    public var pauseSeconds: Int = 5
    public var lockEnabled = false
    public init() {}
    public static let allowedPauses = [0, 5, 10, 15, 30]
}

public enum LocalDay {
    public static func string(_ date: Date = Date(), timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }
}

public struct PlanState: Codable, Equatable {
    public var schemaVersion = 1
    public var hasOnboarded = false
    public var moments: [Moment] = []
    public var activities: [Activity] = []
    public var occurrences: [Occurrence] = []
    public var notes: [PersonalNote] = []
    public var preferences = Preferences()
    public var timer: PracticeTimer?
    public init() {}
    public func activity(_ id: UUID) -> Activity? { activities.first { $0.id == id } }
    public func orderedActivities(in momentID: UUID) -> [Activity] {
        activities.filter { $0.momentID == momentID }.sorted { $0.position < $1.position }
    }
    public func completed(_ id: UUID, on day: String) -> Bool {
        occurrences.contains { $0.id == Occurrence.key(id, day) }
    }
    public mutating func setCompleted(_ id: UUID, day: String, value: Bool, now: Date = Date()) {
        occurrences.removeAll { $0.id == Occurrence.key(id, day) }
        if value { occurrences.append(Occurrence(activityID: id, day: day, completedAt: now)) }
    }
    public mutating func upsert(_ activity: Activity) {
        let oldMoment = self.activity(activity.id)?.momentID
        activities.removeAll { $0.id == activity.id }
        activities.append(activity)
        normalize(activity.momentID)
        if let oldMoment, oldMoment != activity.momentID { normalize(oldMoment) }
    }
    public mutating func moveActivity(_ id: UUID, to momentID: UUID, index: Int) {
        guard moments.contains(where: { $0.id == momentID }), var a = activity(id) else { return }
        let oldMoment = a.momentID
        var ids = orderedActivities(in: momentID).map(\.id).filter { $0 != id }
        ids.insert(id, at: min(max(index, 0), ids.count))
        activities.removeAll { $0.id == id }
        a.momentID = momentID; activities.append(a)
        for (position, item) in ids.enumerated() {
            if let i = activities.firstIndex(where: { $0.id == item }) { activities[i].position = position }
        }
        if oldMoment != momentID { normalize(oldMoment) }
    }
    public mutating func moveMoment(_ id: UUID, to index: Int) {
        guard let i = moments.firstIndex(where: { $0.id == id }) else { return }
        let moment = moments.remove(at: i)
        moments.insert(moment, at: min(max(index, 0), moments.count))
    }
    public mutating func deleteActivity(_ id: UUID) {
        let moment = activity(id)?.momentID
        activities.removeAll { $0.id == id }; notes.removeAll { $0.activityID == id }
        occurrences.removeAll { $0.activityID == id }
        if timer?.activityID == id { timer = nil }
        if let moment { normalize(moment) }
    }
    /// The caller must obtain an explicit choice before deleting records.
    public mutating func deleteMoment(_ id: UUID, movingTo target: UUID?) throws {
        if let target {
            guard target != id, moments.contains(where: { $0.id == target }) else { throw PlanError.invalidMoment }
            for a in orderedActivities(in: id) { moveActivity(a.id, to: target, index: orderedActivities(in: target).count) }
        } else {
            for a in orderedActivities(in: id) { deleteActivity(a.id) }
        }
        moments.removeAll { $0.id == id }
    }
    private mutating func normalize(_ momentID: UUID) {
        let ids = orderedActivities(in: momentID).map(\.id)
        for (position, id) in ids.enumerated() {
            if let i = activities.firstIndex(where: { $0.id == id }) { activities[i].position = position }
        }
    }
    public func validate() throws {
        guard schemaVersion == 1 else { throw PlanError.unsupportedVersion }
        guard Set(moments.map(\.id)).count == moments.count,
              Set(activities.map(\.id)).count == activities.count,
              Set(notes.map(\.id)).count == notes.count,
              Set(occurrences.map(\.id)).count == occurrences.count,
              Preferences.allowedPauses.contains(preferences.pauseSeconds) else { throw PlanError.invalidData }
        for moment in moments where moment.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { throw PlanError.invalidName }
        for activity in activities {
            guard moments.contains(where: { $0.id == activity.momentID }) else { throw PlanError.invalidMoment }
            guard !activity.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw PlanError.invalidName }
            guard !activity.weekdays.isEmpty, activity.weekdays.isSubset(of: Set(1...7)),
                  activity.reminder?.isValid != false,
                  activity.durationMinutes.map({ (1...240).contains($0) }) != false,
                  Set(activity.questions.map(\.id)).count == activity.questions.count else { throw PlanError.invalidData }
        }
        let ids = Set(activities.map(\.id))
        guard notes.allSatisfy({ ids.contains($0.activityID) }),
              occurrences.allSatisfy({ ids.contains($0.activityID) }),
              timer.map({ ids.contains($0.activityID) }) != false else { throw PlanError.invalidData }
    }
}

public enum PlanError: LocalizedError {
    case invalidName, invalidMoment, invalidData, unsupportedVersion
    public var errorDescription: String? {
        switch self {
        case .invalidName: return "Dê um nome ao momento ou à atividade."
        case .invalidMoment: return "Escolha um momento válido para esta atividade."
        case .invalidData: return "Não foi possível validar os dados do plano. O arquivo original foi preservado."
        case .unsupportedVersion: return "Estes dados pertencem a uma versão mais recente do app. Atualize para abri-los."
        }
    }
}
