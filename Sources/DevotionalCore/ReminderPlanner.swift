import Foundation

public struct PlannedReminder: Equatable, Identifiable {
    public let activityID: UUID
    /// nil means every day, one repeating system request instead of seven.
    public let weekday: Int?
    public let time: Reminder
    public var id: String { "practice.\(activityID.uuidString).\(weekday.map(String.init) ?? "daily")" }
}

public struct ReminderPlan {
    public let requests: [PlannedReminder]
    public let omittedActivityIDs: [UUID]
}

public enum ReminderPlanner {
    /// Conservative budget leaves space for the practice timer and future OS needs.
    public static func build(_ state: PlanState, limit: Int = 60) -> ReminderPlan {
        var requests: [PlannedReminder] = []
        var omitted: [UUID] = []
        for moment in state.moments {
            for a in state.orderedActivities(in: moment.id) where a.isEnabled {
                guard let time = a.reminder, time.isValid, !a.weekdays.isEmpty else { continue }
                let days: [Int?] = a.weekdays == Set(1...7) ? [nil] : a.weekdays.sorted().map(Optional.some)
                let group = days.map { PlannedReminder(activityID: a.id, weekday: $0, time: time) }
                if requests.count + group.count <= max(0, limit) { requests += group } else { omitted.append(a.id) }
            }
        }
        return ReminderPlan(requests: requests, omittedActivityIDs: omitted)
    }
}
