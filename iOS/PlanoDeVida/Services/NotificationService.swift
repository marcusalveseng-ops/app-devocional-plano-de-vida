import Foundation
import Combine
import UserNotifications
import DevotionalCore

@MainActor
final class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var status: UNAuthorizationStatus = .notDetermined
    @Published var omitted: [UUID] = []
    @Published var warning: String?
    @Published var scheduledCount = 0
    var onOpenActivity: ((UUID) -> Void)?
    private let center = UNUserNotificationCenter.current()
    private var desiredState: PlanState?
    private var isSynchronizing = false

    override init() { super.init(); center.delegate = self }
    func refreshPermission() async { status = await center.notificationSettings().authorizationStatus }
    func requestPermission() async {
        do { _ = try await center.requestAuthorization(options: [.alert, .sound]) }
        catch { warning = "Não foi possível solicitar a permissão de notificações." }
        await refreshPermission()
    }
    /// Serialize all rebuilds. An edit arriving during an await is processed after this batch.
    func synchronize(_ state: PlanState) async {
        desiredState = state
        guard !isSynchronizing else { return }
        isSynchronizing = true
        defer { isSynchronizing = false }
        while let snapshot = desiredState {
            desiredState = nil
            await refreshPermission()
            let pending = await center.pendingNotificationRequests()
            center.removePendingNotificationRequests(withIdentifiers: pending.filter { $0.identifier.hasPrefix("practice.") || $0.identifier.hasPrefix("timer.") }.map(\.identifier))
            warning = nil; scheduledCount = 0; omitted = []
            guard status == .authorized || status == .provisional else { continue }
            let plan = ReminderPlanner.build(snapshot)
            omitted = plan.omittedActivityIDs
            var expected = Set<String>()
            for reminder in plan.requests {
                if desiredState != nil { break }
                var components = DateComponents()
                components.hour = reminder.time.hour; components.minute = reminder.time.minute
                components.weekday = reminder.weekday
                let content = neutralContent(activityID: reminder.activityID, timer: false)
                let request = UNNotificationRequest(identifier: reminder.id, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true))
                do { try await center.add(request); expected.insert(request.identifier) }
                catch { omitted.append(reminder.activityID) }
            }
            if let timer = snapshot.timer, !timer.isPaused, timer.remaining() > 0, desiredState == nil {
                let request = UNNotificationRequest(identifier: "timer.\(timer.activityID.uuidString)", content: neutralContent(activityID: timer.activityID, timer: true), trigger: UNTimeIntervalNotificationTrigger(timeInterval: max(1, timer.remaining()), repeats: false))
                do { try await center.add(request); expected.insert(request.identifier) }
                catch { warning = "O aviso de término do temporizador não pôde ser agendado." }
            }
            let actual = Set(await center.pendingNotificationRequests().map(\.identifier))
            scheduledCount = actual.filter { $0.hasPrefix("practice.") }.count
            if !expected.isSubset(of: actual), desiredState == nil { warning = "Alguns avisos não foram confirmados pelo iPhone. Revise os lembretes." }
        }
    }
    private func neutralContent(activityID: UUID, timer: Bool) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Plano de Vida"
        content.body = timer ? "Seu tempo de prática terminou." : "Hora da sua prática."
        content.sound = .default
        content.userInfo = ["activityID": activityID.uuidString]
        return content
    }
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let id = (response.notification.request.content.userInfo["activityID"] as? String).flatMap(UUID.init(uuidString:))
        Task { @MainActor [weak self] in if let id { self?.onOpenActivity?(id) }; completionHandler() }
    }
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
