import SwiftUI
import DevotionalCore

struct ExaminationView: View {
    @EnvironmentObject var model: AppModel
    let activity: Activity
    @ObservedObject var player: SpeechPlayer
    @State private var manualIndex = 0
    @State private var manualSession = false
    @State private var manualFinished = false
    private var questions: [Question] { activity.questions.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } }
    private var hasAudio: Bool { player.activityID == activity.id && player.phase != .idle }
    private var finished: Bool { manualFinished || (hasAudio && player.phase == .finished) }
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            if questions.isEmpty {
                ContentUnavailableView("Prepare seu roteiro", systemImage: "text.badge.plus", description: Text("Toque em Editar para adicionar perguntas ou copiar um dos modelos de exame."))
            } else if finished {
                Image(systemName: "leaf").font(.largeTitle).foregroundStyle(Palette.forest)
                Text("Um momento para recomeçar.").font(.system(.title2, design: .serif))
                Text("Se desejar, registre abaixo uma reflexão ou um propósito. Você pode concluir sem escrever.").foregroundStyle(.secondary)
                Button("Voltar ao roteiro") { manualSession = false; manualFinished = false; manualIndex = 0; if hasAudio { player.stop() } }.buttonStyle(.bordered)
            } else if hasAudio || manualSession {
                let index = min(hasAudio ? player.index : manualIndex, questions.count - 1)
                Text("Pergunta \(index + 1) de \(questions.count)").font(.caption.weight(.medium)).foregroundStyle(Palette.forest)
                Text(hasAudio ? player.currentText : questions[index].text).font(.system(.title2, design: .serif)).lineSpacing(7)
                    .frame(maxWidth: .infinity, minHeight: 160, alignment: .leading)
                if hasAudio {
                    if player.phase == .silence || (player.phase == .paused && player.silenceRemaining > 0) {
                        TimelineView(.periodic(from: .now, by: 0.25)) { _ in
                            Label("Pausa para refletir · \(Int(ceil(player.silenceRemaining))) s", systemImage: "leaf").font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    HStack(spacing: 12) {
                        Button { player.previous() } label: { Image(systemName: "backward.end").frame(width: 44, height: 48) }.disabled(index == 0).accessibilityLabel("Pergunta anterior")
                        Button { if player.phase == .paused { player.resume() } else { player.pause() } } label: {
                            Label(player.phase == .paused ? "Continuar" : "Pausar", systemImage: player.phase == .paused ? "play.fill" : "pause.fill").frame(maxWidth: .infinity).padding(.vertical, 12)
                        }.buttonStyle(.borderedProminent)
                        Button { player.next() } label: { Image(systemName: "forward.end").frame(width: 44, height: 48) }.accessibilityLabel("Próxima pergunta")
                    }
                    HStack {
                        Button("Repetir pergunta", systemImage: "arrow.counterclockwise") { player.repeatCurrent() }
                        Spacer()
                        Button("Encerrar") { player.stop(); manualSession = false }
                    }.font(.subheadline).buttonStyle(.borderless)
                } else {
                    HStack {
                        Button("Anterior") { manualIndex = max(0, manualIndex - 1) }.disabled(manualIndex == 0)
                        Spacer()
                        Button(manualIndex == questions.count - 1 ? "Concluir reflexão" : "Próxima pergunta") {
                            if manualIndex == questions.count - 1 { manualFinished = true } else { manualIndex += 1 }
                        }.buttonStyle(.borderedProminent)
                    }
                    Button("Encerrar reflexão") { manualSession = false; manualIndex = 0 }.font(.subheadline)
                }
            } else {
                Text("Recolha o dia com calma.").font(.system(.title2, design: .serif))
                Text("\(questions.count) perguntas, uma de cada vez. Não é necessário escrever respostas.").foregroundStyle(.secondary)
                Button("Ouvir o exame", systemImage: "play.fill") {
                    manualSession = false; manualFinished = false
                    player.start(texts: questions.map(\.text), activityID: activity.id, voiceID: model.state.preferences.voiceID, pauseSeconds: model.state.preferences.pauseSeconds)
                }.buttonStyle(PrimaryButtonStyle())
                Button("Refletir em silêncio", systemImage: "text.bubble") { player.stop(); manualIndex = 0; manualSession = true; manualFinished = false }.buttonStyle(.bordered).frame(maxWidth: .infinity)
                Text("Pausa de \(model.state.preferences.pauseSeconds) segundos após cada pergunta do áudio. A voz e as pausas podem ser alteradas em Ajustes.").font(.footnote).foregroundStyle(.secondary)
            }
        }.padding(22).frame(maxWidth: .infinity, alignment: .leading).background(Palette.card, in: RoundedRectangle(cornerRadius: 22))
            .onChange(of: questions) { _, _ in
                manualSession = false; manualFinished = false; manualIndex = 0
                if hasAudio { player.stop() }
            }
            .alert("Áudio indisponível", isPresented: Binding(get: { player.errorMessage != nil }, set: { if !$0 { player.errorMessage = nil } })) {
                Button("Entendi") { player.errorMessage = nil }
            } message: { Text(player.errorMessage ?? "") }
    }
}
