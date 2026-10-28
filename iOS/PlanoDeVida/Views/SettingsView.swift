import SwiftUI
import AVFoundation
import UserNotifications
import DevotionalCore

struct SettingsView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        Form {
            VoiceSettings(player: model.audio)
            Section {
                Picker("Pausa após cada pergunta", selection: Binding(get: { model.state.preferences.pauseSeconds }, set: { value in model.commit { $0.preferences.pauseSeconds = value } })) {
                    ForEach(Preferences.allowedPauses, id: \.self) { Text($0 == 0 ? "Sem pausa" : "\($0) segundos").tag($0) }
                }
                Text("As pausas são usadas no exame, inclusive após a última pergunta. O Evangelho tem leitura contínua.").font(.footnote).foregroundStyle(.secondary)
            } header: { Text("Reflexão guiada") }
            Section {
                Toggle("Proteger acesso ao app", isOn: Binding(get: { model.state.preferences.lockEnabled }, set: { value in Task { await model.setLock(value) } })).disabled(model.authenticating)
                Text("Use Face ID, Touch ID ou o código do iPhone. Ao retornar ao app, será necessário desbloqueá-lo. O áudio iniciado pode continuar com um título discreto.").font(.footnote).foregroundStyle(.secondary)
            } header: { Text("Privacidade") }
            NotificationSettings(service: model.notifications)
            Section("Seus dados") {
                Label("Guardados somente neste iPhone", systemImage: "iphone")
                Text("Plano, roteiros e notas são armazenados em arquivos protegidos pelo iOS. Não há conta, sincronização, análise de uso ou envio de textos pessoais para serviços de voz.").font(.footnote).foregroundStyle(.secondary)
                Text("Os arquivos pessoais são excluídos do backup do sistema. Não há recuperação garantida após apagar o app, trocar ou perder o aparelho.").font(.footnote).foregroundStyle(.secondary)
            }
            Section("Conteúdo") {
                LabeledContent("Evangelho", value: GospelService().isConfigured ? "Fonte configurada" : "Fonte em preparação")
                Text("A fonte e a edição do Evangelho aguardam autorização de exibição, áudio e eventual armazenamento. Nenhuma passagem é criada por inteligência artificial.").font(.footnote).foregroundStyle(.secondary)
                Text(Editorial.reviewNotice).font(.footnote).foregroundStyle(.secondary)
                LabeledContent("Pacote editorial", value: Editorial.version)
            }
            Section { LabeledContent("Plano de Vida", value: "0.1.0 · desenvolvimento") }
        }.navigationTitle("Ajustes")
    }
}

struct VoiceSettings: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject var player: SpeechPlayer
    @State private var voices = SpeechPlayer.portugueseVoices
    var body: some View {
        Section {
            if voices.isEmpty {
                Text("Nenhuma voz em português foi encontrada. Verifique as vozes em Ajustes do iPhone › Acessibilidade › Conteúdo Falado. Algumas opções precisam ser baixadas.").foregroundStyle(.secondary)
            } else {
                Picker("Voz", selection: Binding(get: { model.state.preferences.voiceID ?? "" }, set: { value in model.commit { $0.preferences.voiceID = value.isEmpty ? nil : value } })) {
                    Text("Padrão em português do Brasil").tag("")
                    if let id = model.state.preferences.voiceID, !voices.contains(where: { $0.identifier == id }) { Text("Voz anterior indisponível").tag(id) }
                    ForEach(voices, id: \.identifier) { voice in Text(SpeechPlayer.label(voice)).tag(voice.identifier) }
                }
                Button("Ouvir amostra", systemImage: "speaker.wave.2") {
                    player.start(texts: ["Reserve este momento para recolher o dia, agradecer e recomeçar com serenidade."], activityID: nil, voiceID: model.state.preferences.voiceID, pauseSeconds: 0)
                }
            }
            Button("Atualizar vozes disponíveis", systemImage: "arrow.clockwise") { voices = SpeechPlayer.portugueseVoices }
            Text("As vozes são do próprio iPhone. A disponibilidade de opções masculinas e femininas depende das vozes instaladas. Ouça a amostra antes de escolher.").font(.footnote).foregroundStyle(.secondary)
        } header: { Text("Voz de leitura") }
            .alert("Áudio indisponível", isPresented: Binding(get: { player.errorMessage != nil }, set: { if !$0 { player.errorMessage = nil } })) { Button("Entendi") { player.errorMessage = nil } } message: { Text(player.errorMessage ?? "") }
    }
}

struct NotificationSettings: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject var service: NotificationService
    var body: some View {
        Section {
            LabeledContent("Permissão", value: statusText)
            if service.status == .denied {
                Button("Abrir ajustes do iPhone") { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }
                Text("Seu plano continua disponível. Reative as notificações nos Ajustes do iPhone quando desejar.").font(.footnote).foregroundStyle(.secondary)
            }
            LabeledContent("Agendamentos confirmados", value: "\(service.scheduledCount)")
            if !service.omitted.isEmpty {
                Text("Sem lembrete ativo para: " + service.omitted.compactMap { model.state.activity($0)?.name }.joined(separator: ", ")).font(.footnote).foregroundStyle(Palette.terracotta)
                Text("Reduza a quantidade de lembretes ou de dias individuais. O plano permanece utilizável.").font(.footnote).foregroundStyle(.secondary)
            }
            if let warning = service.warning { Text(warning).font(.footnote).foregroundStyle(Palette.terracotta) }
            Text("Ative o primeiro lembrete dentro de uma atividade. Os avisos respeitam o Foco, o silêncio e as permissões do iPhone.").font(.footnote).foregroundStyle(.secondary)
        } header: { Text("Lembretes") }
            .task { await service.refreshPermission() }
    }
    private var statusText: String {
        switch service.status {
        case .authorized: return "Permitidos"
        case .provisional: return "Entrega silenciosa"
        case .denied: return "Não permitidos"
        case .ephemeral: return "Temporários"
        case .notDetermined: return "Ainda não solicitada"
        @unknown default: return "Verificar nos Ajustes"
        }
    }
}
