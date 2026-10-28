import SwiftUI
import DevotionalCore

struct ActivityEditor: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) var dismiss
    @State var activity: Activity
    var onSaved: (() -> Void)?
    @State private var reminderEnabled = false
    @State private var reminderTime = Date()
    @State private var durationEnabled = false
    @State private var duration = 10
    @State private var replacingTemplate: String?
    private let weekdays = [(2, "Seg"), (3, "Ter"), (4, "Qua"), (5, "Qui"), (6, "Sex"), (7, "Sáb"), (1, "Dom")]

    var body: some View {
        NavigationStack {
            Form {
                Section("Prática") {
                    TextField("Nome", text: $activity.name).accessibilityIdentifier("activity-name")
                    Picker("Tipo", selection: $activity.kind) { ForEach(ActivityKind.allCases) { Text($0.title).tag($0) } }
                    Picker("Momento", selection: $activity.momentID) { ForEach(model.state.moments) { Text($0.name).tag($0.id) } }
                    Toggle("Atividade ativa", isOn: $activity.isEnabled)
                }
                Section("Dias da semana") {
                    ForEach(weekdays, id: \.0) { day, name in
                        Toggle(name, isOn: Binding(get: { activity.weekdays.contains(day) }, set: { enabled in
                            if enabled { activity.weekdays.insert(day) } else { activity.weekdays.remove(day) }
                        }))
                    }
                    if activity.weekdays.isEmpty { Text("Escolha pelo menos um dia.").foregroundStyle(.red) }
                }
                Section {
                    Toggle("Lembrar desta prática", isOn: $reminderEnabled)
                    if reminderEnabled { DatePicker("Horário", selection: $reminderTime, displayedComponents: .hourAndMinute) }
                } header: { Text("Lembrete") } footer: {
                    Text("O aviso usa somente uma mensagem discreta. O horário não muda ao reorganizar o plano e respeita as configurações de Foco e som do iPhone.")
                }
                if activity.kind.supportsTimer {
                    Section("Tempo para a prática") {
                        Toggle("Usar temporizador", isOn: $durationEnabled)
                        if durationEnabled { Stepper("\(duration) minutos", value: $duration, in: 1...240) }
                    }
                }
                if activity.kind == .spiritualReading {
                    Section {
                        TextField("Título do livro", text: $activity.bookTitle)
                        Text("A leitura do livro é feita fora do app. Uma Ave-Maria acompanha a abertura e o encerramento.").font(.footnote).foregroundStyle(.secondary)
                    } header: { Text("Livro") }
                }
                if activity.kind == .examination {
                    QuestionsEditor(questions: $activity.questions)
                    Section {
                        ForEach(Editorial.examinations) { template in
                            Button("Usar \(template.name.lowercased())") { replacingTemplate = template.id }
                        }
                    } header: { Text("Modelos de roteiro") } footer: { Text(Editorial.reviewNotice) }
                } else if activity.kind != .gospel {
                    Section("Texto de apoio") {
                        TextEditor(text: $activity.supportText).frame(minHeight: 140).accessibilityLabel("Texto de apoio")
                        if activity.supportText.isEmpty {
                            Button("Adicionar Ave-Maria") { activity.supportText = Editorial.hailMary }
                        }
                    }
                }
                if activity.kind != .gospel {
                    Section("Intenção ou propósito opcional") {
                        TextField("Para esta prática", text: $activity.intention, axis: .vertical).lineLimit(2...5)
                    }
                }
                if let error = model.errorMessage { Section { Text(error).foregroundStyle(.red) } }
            }
            .navigationTitle("Editar prática").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Salvar", action: save).disabled(activity.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || activity.weekdays.isEmpty).accessibilityIdentifier("save-activity") }
            }
            .confirmationDialog("Substituir as perguntas deste bloco pelo modelo?", isPresented: Binding(get: { replacingTemplate != nil }, set: { if !$0 { replacingTemplate = nil } }), titleVisibility: .visible) {
                Button("Substituir perguntas", role: .destructive) {
                    if let template = Editorial.examinations.first(where: { $0.id == replacingTemplate }) { activity.questions = template.copyQuestions() }
                    replacingTemplate = nil
                }
            } message: { Text("As anotações pessoais são mantidas. Outros blocos não serão alterados.") }
        }
        .onAppear {
            reminderEnabled = activity.reminder != nil
            let suggested = activity.reminder ?? Reminder(hour: activity.kind == .examination ? 19 : 12)
            reminderTime = Calendar.current.date(bySettingHour: suggested.hour, minute: suggested.minute, second: 0, of: Date()) ?? Date()
            durationEnabled = activity.durationMinutes != nil; duration = activity.durationMinutes ?? 10
        }
    }
    private func save() {
        activity.name = activity.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let c = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        activity.reminder = reminderEnabled ? Reminder(hour: c.hour ?? 12, minute: c.minute ?? 0) : nil
        activity.durationMinutes = durationEnabled && activity.kind.supportsTimer ? duration : nil
        activity.questions.removeAll { $0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let previous = model.state.activity(activity.id)
        if previous?.momentID != activity.momentID { activity.position = model.state.orderedActivities(in: activity.momentID).count }
        let request = reminderEnabled && (previous?.reminder == nil || model.notifications.status == .notDetermined)
        if model.commit(requestNotificationPermission: request, { $0.upsert(activity) }) { dismiss(); onSaved?() }
    }
}

struct QuestionsEditor: View {
    @Binding var questions: [Question]
    var body: some View {
        Section {
            ForEach($questions) { $question in
                VStack(alignment: .leading, spacing: 8) {
                    TextEditor(text: $question.text).frame(minHeight: 90).accessibilityLabel("Pergunta do exame")
                    HStack {
                        Button { shift(question.id, by: -1) } label: { Image(systemName: "arrow.up").frame(width: 44, height: 40) }.disabled(questions.first?.id == question.id).accessibilityLabel("Mover pergunta para cima")
                        Button { shift(question.id, by: 1) } label: { Image(systemName: "arrow.down").frame(width: 44, height: 40) }.disabled(questions.last?.id == question.id).accessibilityLabel("Mover pergunta para baixo")
                        Spacer()
                        Button(role: .destructive) { questions.removeAll { $0.id == question.id } } label: { Image(systemName: "trash").frame(width: 44, height: 40) }.accessibilityLabel("Excluir pergunta")
                    }.buttonStyle(.borderless)
                }
            }
            .onMove { questions.move(fromOffsets: $0, toOffset: $1) }
            Button { questions.append(Question(text: "")) } label: { Label("Adicionar pergunta", systemImage: "plus") }
        } header: { Text("Perguntas do roteiro") } footer: {
            Text("Cada campo é uma pergunta. As respostas e reflexões pessoais ficam nas anotações da atividade.")
        }
    }
    private func shift(_ id: UUID, by delta: Int) {
        guard let index = questions.firstIndex(where: { $0.id == id }) else { return }
        let target = index + delta
        guard questions.indices.contains(target) else { return }
        questions.swapAt(index, target)
    }
}
