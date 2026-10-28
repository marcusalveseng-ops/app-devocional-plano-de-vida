import SwiftUI
import DevotionalCore

struct GospelView: View {
    @EnvironmentObject var model: AppModel
    @StateObject private var service = GospelService()
    let activityID: UUID
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(Date(), format: .dateTime.day().month(.wide).year()).font(.subheadline).foregroundStyle(.secondary)
            if let content = service.content, content.date == model.today {
                Text(content.reference).font(.title2.bold())
                Text(content.text).font(.system(.title3, design: .serif)).lineSpacing(7).textSelection(.enabled)
                Text("Data da leitura: \(content.date)").font(.caption).foregroundStyle(.secondary)
                Link("Fonte: \(content.sourceName)", destination: content.sourceURL).font(.footnote)
                Text(content.edition).font(.caption).foregroundStyle(.secondary)
                if service.audioAllowed {
                    Button("Ouvir o Evangelho", systemImage: "play.fill") {
                        guard content.date == LocalDay.string() else { model.today = LocalDay.string(); return }
                        model.audio.start(texts: [content.text], activityID: activityID, voiceID: model.state.preferences.voiceID, pauseSeconds: 0)
                    }.buttonStyle(PrimaryButtonStyle())
                }
            } else if !service.loading {
                Image(systemName: "book.closed").font(.largeTitle).foregroundStyle(Palette.forest)
                Text(service.isConfigured ? "Leitura indisponível" : "O Evangelho está a caminho").font(.system(.title2, design: .serif))
            }
            if let message = service.message { Text(message).foregroundStyle(.secondary) }
            if service.loading { ProgressView("Buscando a leitura desta data…") }
            if service.isConfigured {
                Button("Tentar novamente", systemImage: "arrow.clockwise") { Task { await service.load(day: model.today) } }.buttonStyle(.bordered).disabled(service.loading)
            }
        }
        .task(id: model.today) { await service.load(day: model.today) }
        .alert("Áudio indisponível", isPresented: Binding(get: { model.audio.errorMessage != nil }, set: { if !$0 { model.audio.errorMessage = nil } })) {
            Button("Entendi") { model.audio.errorMessage = nil }
        } message: { Text(model.audio.errorMessage ?? "") }
    }
}
