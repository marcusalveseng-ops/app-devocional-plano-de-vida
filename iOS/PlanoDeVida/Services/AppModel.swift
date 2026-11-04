import SwiftUI
import LocalAuthentication
import DevotionalCore

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var state = PlanState()
    @Published var errorMessage: String?
    @Published private(set) var loadFailed = false
    @Published private(set) var isLocked = false
    @Published var privacyShield = false
    @Published var selectedActivity: UUID?
    @Published var today = LocalDay.string()
    @Published private(set) var authenticating = false
    @Published var authenticationMessage: String?
    let notifications = NotificationService()
    let audio = SpeechPlayer()
    private let repository: PlanRepository
    private var pendingActivity: UUID?

    init() {
        var directoryName = "PlanoDeVida"
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ui-testing") { directoryName = "PlanoDeVidaUITests" }
        #endif
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent(directoryName, isDirectory: true)
        repository = PlanRepository(fileURL: directory.appendingPathComponent("plan-v1.json"))
        #if DEBUG
        if directoryName == "PlanoDeVidaUITests", ProcessInfo.processInfo.arguments.contains("-ui-testing-reset") { try? FileManager.default.removeItem(at: repository.fileURL) }
        #endif
        do { state = try repository.load(); isLocked = state.preferences.lockEnabled }
        catch { loadFailed = true; errorMessage = "Não foi possível abrir seus dados. Feche e abra o app após desbloquear o iPhone. Seus arquivos foram preservados." }
        notifications.onOpenActivity = { [weak self] id in self?.openActivity(id) }
    }
    @discardableResult
    func commit(requestNotificationPermission: Bool = false, _ change: (inout PlanState) throws -> Void) -> Bool {
        guard !loadFailed else { return false }
        do {
            var next = state; try change(&next)
            if let timer = next.timer, next.activity(timer.activityID)?.isEnabled != true { next.timer = nil }
            try repository.save(next)
            let scheduleChanged = ReminderPlanner.build(state).requests != ReminderPlanner.build(next).requests || state.timer != next.timer
            state = next
            if let id = audio.activityID, state.activity(id)?.isEnabled != true { audio.stop() }
            if scheduleChanged || requestNotificationPermission { Task {
                if requestNotificationPermission { await notifications.requestPermission() }
                await notifications.synchronize(state)
            } }
            return true
        } catch { errorMessage = error.localizedDescription; return false }
    }
    func onboard(useTemplate: Bool) {
        commit {
            $0 = useTemplate ? Editorial.starterPlan() : PlanState()
            $0.hasOnboarded = true
            if !useTemplate { $0.moments = [Moment(name: "Ao acordar"), Moment(name: "Durante o dia"), Moment(name: "Antes de dormir")] }
        }
    }
    func foreground() {
        privacyShield = UIApplication.shared.applicationState != .active
        today = LocalDay.string()
        Task { await notifications.synchronize(state) }
    }
    func conceal() {
        privacyShield = true
        if state.preferences.lockEnabled && !authenticating { isLocked = true }
    }
    func openActivity(_ id: UUID) {
        guard state.activity(id) != nil else { return }
        if isLocked { pendingActivity = id } else { selectedActivity = id }
    }
    func unlock() async {
        guard !authenticating else { return }
        authenticating = true; authenticationMessage = nil
        defer { authenticating = false }
        let context = LAContext()
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Acesse seu plano e suas anotações pessoais.")
            if success {
                isLocked = false; privacyShield = false
                if let pendingActivity { selectedActivity = pendingActivity; self.pendingActivity = nil }
            }
        } catch { authenticationMessage = "O acesso continua protegido. Toque em Desbloquear para tentar novamente." }
    }
    func setLock(_ enabled: Bool) async {
        guard !authenticating else { return }
        let context = LAContext(); var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            errorMessage = "Configure um código de acesso nos Ajustes do iPhone para proteger o app."
            return
        }
        authenticating = true
        defer { authenticating = false }
        do {
            if try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: enabled ? "Confirme a proteção do seu plano." : "Confirme a desativação da proteção do seu plano.") {
                if commit({ $0.preferences.lockEnabled = enabled }) { isLocked = false; privacyShield = false }
            }
        } catch { errorMessage = "A configuração de proteção não foi alterada." }
    }
    func toggleCompletion(_ id: UUID) {
        today = LocalDay.string()
        let complete = !state.completed(id, on: today)
        commit { $0.setCompleted(id, day: today, value: complete) }
    }
    func startTimer(_ activity: Activity) {
        commit { $0.timer = PracticeTimer(activityID: activity.id, seconds: TimeInterval((activity.durationMinutes ?? 10) * 60)) }
    }
    func pauseTimer() { commit { $0.timer?.pause() } }
    func resumeTimer() { commit { $0.timer?.resume() } }
    func stopTimer() { commit { $0.timer = nil } }
}
