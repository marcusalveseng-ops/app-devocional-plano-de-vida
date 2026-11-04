import AVFoundation
import MediaPlayer
import Combine
import DevotionalCore

@MainActor
final class SpeechPlayer: NSObject, ObservableObject, AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
    enum Phase { case idle, speaking, silence, paused, finished }
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var index = 0
    @Published private(set) var activityID: UUID?
    @Published private(set) var texts: [String] = []
    @Published var errorMessage: String?
    private let synthesizer = AVSpeechSynthesizer()
    private var utterance: AVSpeechUtterance?
    private var silence: AVAudioPlayer?
    private var pausedPhase: Phase = .speaking
    private var needsRestart = false
    private var pauseSeconds = 0
    private var voice: AVSpeechSynthesisVoice?
    private var observers: [NSObjectProtocol] = []
    private var remoteTargets: [(MPRemoteCommand, Any)] = []

    var currentText: String { texts.indices.contains(index) ? texts[index] : "" }
    var silenceRemaining: TimeInterval { max(0, (silence?.duration ?? 0) - (silence?.currentTime ?? 0)) }
    var isActive: Bool { phase != .idle && phase != .finished }
    static var portugueseVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("pt") }.sorted {
            if ($0.language == "pt-BR") != ($1.language == "pt-BR") { return $0.language == "pt-BR" }
            return $0.name < $1.name
        }
    }
    static func label(_ voice: AVSpeechSynthesisVoice) -> String {
        let gender = voice.gender == .male ? "masculina" : voice.gender == .female ? "feminina" : "voz do sistema"
        return "\(voice.name) · \(voice.language) · \(gender)"
    }

    override init() {
        super.init(); synthesizer.delegate = self
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] notification in
            let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            Task { @MainActor in if raw == AVAudioSession.InterruptionType.began.rawValue { self?.interrupt() } }
        })
        observers.append(center.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] notification in
            let reason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            Task { @MainActor in if reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue { self?.interrupt() } }
        })
        let remote = MPRemoteCommandCenter.shared()
        remoteTargets.append((remote.pauseCommand, remote.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }; return .success
        }))
        remoteTargets.append((remote.playCommand, remote.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.resume() }; return .success
        }))
        remoteTargets.append((remote.togglePlayPauseCommand, remote.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in guard let self else { return }; if self.phase == .paused { self.resume() } else { self.pause() } }; return .success
        }))
    }

    func start(texts: [String], activityID: UUID?, voiceID: String?, pauseSeconds: Int) {
        stop()
        let items = texts.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !items.isEmpty else { errorMessage = "Adicione perguntas ao roteiro antes de iniciar."; return }
        let available = Self.portugueseVoices
        if let voiceID {
            guard let selected = available.first(where: { $0.identifier == voiceID }) else {
                errorMessage = "A voz escolhida não está disponível neste iPhone. Escolha outra voz em Ajustes."
                return
            }
            voice = selected
        } else {
            guard let selected = available.first(where: { $0.language == "pt-BR" }) else {
                errorMessage = "Escolha uma voz em português nos Ajustes. Novas vozes podem precisar de download nos Ajustes de Acessibilidade do iPhone."
                return
            }
            voice = selected
        }
        guard activateSession() else { return }
        self.texts = items; self.activityID = activityID; self.pauseSeconds = pauseSeconds
        index = 0; speakCurrent()
    }
    private func activateSession() -> Bool {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true)
            return true
        } catch { errorMessage = "Não foi possível iniciar o áudio. Tente novamente."; return false }
    }
    private func speakCurrent() {
        cancelCurrent()
        guard texts.indices.contains(index) else { finish(); return }
        let item = AVSpeechUtterance(string: texts[index])
        item.voice = voice; item.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance = item; phase = .speaking; needsRestart = false
        synthesizer.speak(item); updateNowPlaying()
    }
    func pause() {
        guard phase == .speaking || phase == .silence else { return }
        pausedPhase = phase
        if phase == .silence { silence?.pause() }
        else if !synthesizer.pauseSpeaking(at: .immediate) { utterance = nil; synthesizer.stopSpeaking(at: .immediate); needsRestart = true }
        phase = .paused; updateNowPlaying()
    }
    func resume() {
        guard phase == .paused, activateSession() else { return }
        if needsRestart { speakCurrent(); return }
        phase = pausedPhase
        if pausedPhase == .silence { silence?.play() }
        else if !synthesizer.continueSpeaking() { speakCurrent() }
        updateNowPlaying()
    }
    private func interrupt() {
        guard isActive, phase != .paused else { return }
        let wasSpeaking = phase == .speaking
        pause()
        if wasSpeaking { utterance = nil; synthesizer.stopSpeaking(at: .immediate); needsRestart = true }
    }
    func repeatCurrent() { guard !texts.isEmpty, activateSession() else { return }; speakCurrent() }
    func next() {
        guard !texts.isEmpty else { return }
        cancelCurrent(); index += 1
        if index >= texts.count { finish() } else if activateSession() { speakCurrent() }
    }
    func previous() { guard !texts.isEmpty, activateSession() else { return }; index = max(0, min(index - 1, texts.count - 1)); speakCurrent() }
    func stop() {
        cancelCurrent(); phase = .idle; texts = []; index = 0; activityID = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        setRemoteEnabled(false)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    private func cancelCurrent() {
        utterance = nil; silence?.delegate = nil; silence?.stop(); silence = nil
        synthesizer.stopSpeaking(at: .immediate)
    }
    private func finish() {
        cancelCurrent(); phase = .finished
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil; setRemoteEnabled(false)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    private func beginSilence() {
        guard pauseSeconds > 0 else { next(); return }
        do {
            // The finite silence is the requested reflection interval, including after the final question.
            let player = try AVAudioPlayer(data: Self.silenceWAV(seconds: pauseSeconds))
            silence = player; player.delegate = self
            phase = .silence; player.prepareToPlay()
            if !player.play() { errorMessage = "Não foi possível iniciar a pausa. Retome a pergunta."; pausedPhase = .speaking; needsRestart = true; phase = .paused }
            updateNowPlaying()
        } catch { errorMessage = "Não foi possível iniciar a pausa. Retome a pergunta."; needsRestart = true; phase = .paused }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            guard let self, self.utterance === utterance else { return }
            self.utterance = nil; self.beginSilence()
        }
    }
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            guard let self, player === self.silence else { return }
            if flag { self.next() } else { self.errorMessage = "A pausa foi interrompida. Retome a pergunta."; self.phase = .paused; self.needsRestart = true }
        }
    }
    private func updateNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: "Momento de reflexão",
            MPMediaItemPropertyArtist: "Plano de Vida",
            MPNowPlayingInfoPropertyPlaybackRate: phase == .paused ? 0.0 : 1.0
        ]
        setRemoteEnabled(true)
    }
    private func setRemoteEnabled(_ enabled: Bool) {
        let commands = MPRemoteCommandCenter.shared()
        commands.playCommand.isEnabled = enabled; commands.pauseCommand.isEnabled = enabled
        commands.togglePlayPauseCommand.isEnabled = enabled
    }
    private static func silenceWAV(seconds: Int) -> Data {
        let samples = UInt32(seconds * 8000), byteCount = samples * 2
        var data = Data()
        func append<T: FixedWidthInteger>(_ value: T) { var v = value.littleEndian; withUnsafeBytes(of: &v) { data.append(contentsOf: $0) } }
        data.append(contentsOf: "RIFF".utf8); append(UInt32(36) + byteCount)
        data.append(contentsOf: "WAVEfmt ".utf8); append(UInt32(16)); append(UInt16(1)); append(UInt16(1))
        append(UInt32(8000)); append(UInt32(16000)); append(UInt16(2)); append(UInt16(16))
        data.append(contentsOf: "data".utf8); append(byteCount)
        data.append(Data(count: Int(byteCount)))
        return data
    }
}
