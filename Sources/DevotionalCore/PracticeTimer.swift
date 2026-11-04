import Foundation

/// Wall-clock based: suspension/backgrounding never consumes extra or fewer seconds.
public struct PracticeTimer: Codable, Equatable {
    public var activityID: UUID
    public private(set) var deadline: Date?
    public private(set) var pausedRemaining: TimeInterval
    public let totalSeconds: TimeInterval
    public init(activityID: UUID, seconds: TimeInterval, now: Date = Date()) {
        self.activityID = activityID; totalSeconds = max(0, seconds)
        pausedRemaining = max(0, seconds); deadline = now.addingTimeInterval(max(0, seconds))
    }
    public var isPaused: Bool { deadline == nil }
    public func remaining(at now: Date = Date()) -> TimeInterval {
        max(0, deadline.map { $0.timeIntervalSince(now) } ?? pausedRemaining)
    }
    public mutating func pause(at now: Date = Date()) {
        guard deadline != nil else { return }
        pausedRemaining = remaining(at: now); deadline = nil
    }
    public mutating func resume(at now: Date = Date()) {
        guard isPaused, pausedRemaining > 0 else { return }
        deadline = now.addingTimeInterval(pausedRemaining)
    }
}
