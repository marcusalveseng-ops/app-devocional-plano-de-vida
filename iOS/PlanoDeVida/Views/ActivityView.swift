import SwiftUI
import DevotionalCore

struct ActivityView: View {
    @EnvironmentObject var model: AppModel
    let activityID: UUID
    @State private var editing: Activity?
    @State private var noteEditor: NoteDraft?
    @State private var deletingNote: PersonalNote?
    var body: some View {
        Group {
            if let activity = model.state.activity(activityID) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack(spacing: 14) {
                            Image(systemName: activity.kind.symbol).font(.largeTitle).foregroundStyle(Palette.forest)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(activity.name).font(.system(.title, design: .serif))
                                Text(model.state.moments.first(where: { $0.id == activity.momentID })?.name ?? "").font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        if !activity.intention.isEmpty { Label(activity.intention, systemImage: "heart").font(.subheadline).foregroundStyle(.secondary) }
                        if activity.kind == .gospel { GospelView(activityID: activity.id) }
                        else if activity.kind == .examination { ExaminationView(activity: activity, player: model.audio) }
                        else {
                            if !activity.bookTitle.isEmpty { Label(activity.bookTitle, systemImage: "book.closed").font(.headline) }
                            if !activity.supportText.isEmpty { Text(activity.supportText).font(.system(.title3, design: .serif)).lineSpacing(7).textSelection(.enabled) }
                            if activity.kind.supportsTimer, activity.durationMinutes != nil { PracticeTimerView(activity: activity) }
                            if activity.kind == .free && activity.supportText.isEmpty { Text("Reserve este momento para a sua prática. Quando desejar, registre uma nota ou marque a realização.").foregroundStyle(.secondary) }
                        }
                        Button { model.toggleCompletion(activity.id) } label: {
                            Label(model.state.completed(activity.id, on: model.today) ? "Realizada hoje · desmarcar" : "Marcar como realizada hoje", systemImage: model.state.completed(activity.id, on: model.today) ? "checkmark.circle.fill" : "checkmark.circle")
                                .frame(maxWidth: .infinity).padding(.vertical, 8)
                        }.buttonStyle(.bordered).accessibilityIdentifier("complete-activity")
                        Divider()
                        HStack {
                            Text("Minhas anotações").font(.title3.bold())
                            Spacer()
                            Button { noteEditor = NoteDraft(activityID: activity.id, day: LocalDay.string()) } label: { Image(systemName: "plus").frame(width: 44, height: 44) }.accessibilityLabel("Nova anotação")
                        }
                        let notes = model.state.notes.filter { $0.activityID == activity.id }.sorted { $0.createdAt > $1.createdAt }
                        if notes.isEmpty { Text("Guarde aqui uma reflexão ou um propósito. Escrever é opcional.").font(.subheadline).foregroundStyle(.secondary) }
                        ForEach(notes) { note in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(note.createdAt, format: .dateTime.day().month().year()).font(.caption).foregroundStyle(.secondary)
                                Text(note.text).lineLimit(4)
                                HStack {
                                    Button("Editar") { noteEditor = NoteDraft(note: note) }.buttonStyle(.borderless)
                                    Spacer()
                                    Button("Excluir", role: .destructive) { deletingNote = note }.buttonStyle(.borderless)
                                }.font(.subheadline).padding(.top, 4)
                            }.padding(18).frame(maxWidth: .infinity, alignment: .leading).background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
                        }
                    }.padding(24).frame(maxWidth: 600)
                }.background(Palette.canvas)
                    .toolbar { Button("Editar") { editing = activity } }
            } else {
                ContentUnavailableView("Atividade removida", systemImage: "square.dashed", description: Text("Volte ao plano para escolher outra prática."))
            }
        }
        .navigationTitle("Sua prática").navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { ActivityEditor(activity: $0).protectedContent() }
        .sheet(item: $noteEditor) { NoteEditor(draft: $0).protectedContent() }
        .confirmationDialog("Apagar esta anotação?", isPresented: Binding(get: { deletingNote != nil }, set: { if !$0 { deletingNote = nil } }), titleVisibility: .visible) {
            Button("Apagar anotação", role: .destructive) { if let note = deletingNote { model.commit { $0.notes.removeAll { $0.id == note.id } } }; deletingNote = nil }
        } message: { Text("A anotação será removida deste iPhone. Esta ação não pode ser desfeita.") }
    }
}

struct NoteDraft: Identifiable {
    let id: UUID
    let activityID: UUID
    let day: String
    var text: String
    let existing: PersonalNote?
    init(activityID: UUID, day: String) { id = UUID(); self.activityID = activityID; self.day = day; text = ""; existing = nil }
    init(note: PersonalNote) { id = note.id; activityID = note.activityID; day = note.day; text = note.text; existing = note }
}

struct NoteEditor: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) var dismiss
    @State var draft: NoteDraft
    @State private var discard = false
    var dirty: Bool { draft.text != (draft.existing?.text ?? "") }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $draft.text).frame(minHeight: 260).accessibilityLabel("Sua anotação").accessibilityIdentifier("note-text")
                } footer: { Text("Toque em Salvar para guardar a anotação somente neste iPhone.") }
                if let error = model.errorMessage { Text(error).foregroundStyle(.red) }
            }.navigationTitle("Anotação pessoal").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { if dirty { discard = true } else { dismiss() } } }
                    ToolbarItem(placement: .confirmationAction) { Button("Salvar") {
                        var note = draft.existing ?? PersonalNote(id: draft.id, activityID: draft.activityID, day: draft.day, text: draft.text)
                        note.text = draft.text; note.modifiedAt = Date()
                        if model.commit({ state in state.notes.removeAll { $0.id == note.id }; state.notes.append(note) }) { dismiss() }
                    }.disabled(draft.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("save-note") }
                }
                .confirmationDialog("Descartar as alterações não salvas?", isPresented: $discard, titleVisibility: .visible) { Button("Descartar alterações", role: .destructive) { dismiss() } }
        }.interactiveDismissDisabled(dirty)
    }
}

struct PracticeTimerView: View {
    @EnvironmentObject var model: AppModel
    let activity: Activity
    @State private var openingPrayer = false
    @State private var closingPrayer = false
    @State private var replaceTimer = false
    var body: some View {
        VStack(spacing: 18) {
            if let timer = model.state.timer, timer.activityID == activity.id {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let remaining = timer.remaining(at: context.date)
                    VStack(spacing: 18) {
                        Text(timeString(remaining)).font(.system(.largeTitle, design: .rounded).monospacedDigit()).accessibilityLabel("\(Int(ceil(remaining / 60))) minutos restantes")
                        if remaining > 0 {
                            Text(timer.isPaused ? "Tempo pausado" : "Um tempo para estar presente").font(.subheadline).foregroundStyle(.secondary)
                            HStack {
                                Button(timer.isPaused ? "Continuar" : "Pausar", systemImage: timer.isPaused ? "play" : "pause") { if timer.isPaused { model.resumeTimer() } else { model.pauseTimer() } }.buttonStyle(.bordered)
                                Button("Encerrar", systemImage: "stop") { model.stopTimer(); closingPrayer = activity.kind == .spiritualReading }.buttonStyle(.bordered)
                            }
                        } else {
                            Text("O tempo reservado terminou.").font(.headline)
                            if activity.kind == .spiritualReading { prayerBlock(title: "Oração de encerramento") }
                            Button("Concluir temporizador") { model.stopTimer() }.buttonStyle(.bordered)
                            Text("A realização da prática é marcada por você.").font(.footnote).foregroundStyle(.secondary)
                        }
                    }.frame(maxWidth: .infinity)
                }
            } else if openingPrayer {
                prayerBlock(title: "Antes da leitura")
                Button("Começar a contagem") { startTimer() }.buttonStyle(PrimaryButtonStyle())
            } else {
                if closingPrayer { prayerBlock(title: "Oração de encerramento") }
                Text("\(activity.durationMinutes ?? 10) minutos").font(.system(.title, design: .rounded))
                Button(activity.kind == .spiritualReading ? "Iniciar leitura" : "Iniciar temporizador", systemImage: "play.fill") {
                    if activity.kind == .spiritualReading { openingPrayer = true; closingPrayer = false } else { startTimer() }
                }.buttonStyle(PrimaryButtonStyle())
            }
        }.padding(22).frame(maxWidth: .infinity).background(Palette.card, in: RoundedRectangle(cornerRadius: 22))
            .confirmationDialog("Substituir o temporizador de outra prática?", isPresented: $replaceTimer, titleVisibility: .visible) {
                Button("Encerrar o anterior e começar este") { model.startTimer(activity); openingPrayer = false; closingPrayer = false }
            }
    }
    private func startTimer() {
        if let timer = model.state.timer, timer.activityID != activity.id, timer.remaining() > 0 { replaceTimer = true }
        else { model.startTimer(activity); openingPrayer = false; closingPrayer = false }
    }
    private func prayerBlock(title: String) -> some View {
        VStack(alignment: .leading, spacing: 12) { Text(title).font(.headline); Text(Editorial.hailMary).font(.system(.body, design: .serif)).lineSpacing(5) }
    }
    private func timeString(_ seconds: TimeInterval) -> String { let value = Int(ceil(seconds)); return String(format: "%02d:%02d", value / 60, value % 60) }
}
