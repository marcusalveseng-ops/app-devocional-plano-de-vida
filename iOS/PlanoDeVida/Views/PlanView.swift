import SwiftUI
import DevotionalCore

struct PlanView: View {
    @EnvironmentObject var model: AppModel
    @State private var editingActivity: Activity?
    @State private var catalogMoment: Moment?
    @State private var editingMoment: Moment?
    @State private var addingMoment = false
    @State private var deletingActivity: Activity?
    @State private var deletingMoment: Moment?
    var body: some View {
        List {
            Section {
                Text("Organize os momentos do seu dia. Arraste os blocos ou use o menu de cada atividade para movê-los.").font(.subheadline).foregroundStyle(.secondary)
            }
            ForEach(model.state.moments) { moment in
                Section {
                    let activities = model.state.orderedActivities(in: moment.id)
                    ForEach(activities) { activity in
                        HStack {
                            Button { editingActivity = activity } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: activity.kind.symbol).foregroundStyle(Palette.forest).frame(width: 28)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(activity.name).foregroundStyle(.primary)
                                        Text(activity.isEnabled ? scheduleText(activity) : "Desativada").font(.caption).foregroundStyle(.secondary)
                                    }
                                }.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                            }.buttonStyle(.plain)
                            Menu {
                                Button("Abrir prática", systemImage: "arrow.up.right") { model.openActivity(activity.id) }
                                Button("Editar", systemImage: "pencil") { editingActivity = activity }
                                Button("Mover para cima", systemImage: "arrow.up") { model.commit { $0.moveActivity(activity.id, to: moment.id, index: activity.position - 1) } }.disabled(activity.position == 0)
                                Button("Mover para baixo", systemImage: "arrow.down") { model.commit { $0.moveActivity(activity.id, to: moment.id, index: activity.position + 1) } }.disabled(activity.position >= activities.count - 1)
                                Menu("Mover para outro momento") {
                                    ForEach(model.state.moments.filter { $0.id != moment.id }) { target in
                                        Button(target.name) { model.commit { $0.moveActivity(activity.id, to: target.id, index: $0.orderedActivities(in: target.id).count) } }
                                    }
                                }
                                Button(activity.isEnabled ? "Desativar" : "Ativar") { model.commit { state in if let i = state.activities.firstIndex(where: { $0.id == activity.id }) { state.activities[i].isEnabled.toggle() } } }
                                Button("Excluir atividade", role: .destructive) { deletingActivity = activity }
                            } label: { Image(systemName: "ellipsis.circle").frame(width: 44, height: 44) }.accessibilityLabel("Opções de \(activity.name)")
                        }
                        .draggable("activity:\(activity.id.uuidString)")
                        .dropDestination(for: String.self) { items, _ in handleDrop(items, moment: moment, index: activity.position) }
                    }
                    .onMove { offsets, destination in
                        var ordered = activities; ordered.move(fromOffsets: offsets, toOffset: destination)
                        model.commit { state in for (index, activity) in ordered.enumerated() { state.moveActivity(activity.id, to: moment.id, index: index) } }
                    }
                    Button { catalogMoment = moment } label: { Label("Adicionar prática", systemImage: "plus.circle").padding(.vertical, 4) }
                        .dropDestination(for: String.self) { items, _ in handleDrop(items, moment: moment, index: activities.count) }
                } header: {
                    HStack {
                        Text(moment.name)
                        Spacer()
                        Menu {
                            Button("Renomear", systemImage: "pencil") { editingMoment = moment }
                            let index = model.state.moments.firstIndex(where: { $0.id == moment.id }) ?? 0
                            Button("Mover para cima", systemImage: "arrow.up") { model.commit { $0.moveMoment(moment.id, to: index - 1) } }.disabled(index == 0)
                            Button("Mover para baixo", systemImage: "arrow.down") { model.commit { $0.moveMoment(moment.id, to: index + 1) } }.disabled(index == model.state.moments.count - 1)
                            Button("Excluir momento", role: .destructive) { deletingMoment = moment }
                        } label: { Image(systemName: "ellipsis").frame(width: 44, height: 32) }.accessibilityLabel("Opções de \(moment.name)")
                    }.textCase(nil)
                }
            }
            Button { addingMoment = true } label: { Label("Novo momento do dia", systemImage: "plus").padding(.vertical, 8) }
        }
        .navigationTitle("Meu plano")
        .toolbar { EditButton().accessibilityLabel("Reordenar atividades") }
        .sheet(item: $editingActivity) { ActivityEditor(activity: $0).protectedContent() }
        .sheet(item: $catalogMoment) { CatalogView(moment: $0).protectedContent() }
        .sheet(item: $editingMoment) { MomentEditor(moment: $0).protectedContent() }
        .sheet(isPresented: $addingMoment) { MomentEditor(moment: nil).protectedContent() }
        .confirmationDialog("Excluir esta atividade e todos os seus registros?", isPresented: Binding(get: { deletingActivity != nil }, set: { if !$0 { deletingActivity = nil } }), titleVisibility: .visible) {
            Button("Excluir atividade, notas e realizações", role: .destructive) { if let activity = deletingActivity { model.commit { $0.deleteActivity(activity.id) } }; deletingActivity = nil }
        } message: { Text("As notas desta atividade serão apagadas deste iPhone. Esta ação não pode ser desfeita.") }
        .confirmationDialog("O que fazer com este momento?", isPresented: Binding(get: { deletingMoment != nil }, set: { if !$0 { deletingMoment = nil } }), titleVisibility: .visible) {
            if let source = deletingMoment {
                ForEach(model.state.moments.filter { $0.id != source.id }) { target in
                    Button("Mover atividades para \(target.name)") { model.commit { try $0.deleteMoment(source.id, movingTo: target.id) }; deletingMoment = nil }
                }
                Button("Excluir momento e seus registros", role: .destructive) { model.commit { try $0.deleteMoment(source.id, movingTo: nil) }; deletingMoment = nil }
            }
        } message: { Text("Você pode conservar as atividades e as notas movendo-as para outro momento, ou confirmar a exclusão de tudo que pertence a este momento.") }
    }
    private func handleDrop(_ items: [String], moment: Moment, index: Int) -> Bool {
        guard let item = items.first, item.hasPrefix("activity:"), let id = UUID(uuidString: String(item.dropFirst(9))), model.state.activity(id) != nil else { return false }
        return model.commit { $0.moveActivity(id, to: moment.id, index: index) }
    }
    private func scheduleText(_ activity: Activity) -> String {
        let days = activity.weekdays.count == 7 ? "Todos os dias" : "\(activity.weekdays.count) dias por semana"
        return activity.reminder.map { "\(days) · \($0.display)" } ?? days
    }
}

struct MomentEditor: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) var dismiss
    let moment: Moment?
    @State private var name = ""
    var body: some View {
        NavigationStack {
            Form { TextField("Nome do momento", text: $name).accessibilityIdentifier("moment-name") }
                .navigationTitle(moment == nil ? "Novo momento" : "Renomear momento").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Salvar") {
                        if model.commit({ state in
                            if let moment, let i = state.moments.firstIndex(where: { $0.id == moment.id }) { state.moments[i].name = name.trimmingCharacters(in: .whitespacesAndNewlines) }
                            else { state.moments.append(Moment(name: name.trimmingCharacters(in: .whitespacesAndNewlines))) }
                        }) { dismiss() }
                    }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
                }
        }.onAppear { name = moment?.name ?? "" }
    }
}

struct CatalogView: View {
    @Environment(\.dismiss) var dismiss
    let moment: Moment
    @State private var draft: Activity?
    private let entries: [(String, ActivityKind)] = [
        ("Oferecimento de obras", .devotion), ("Terço", .devotion), ("Ângelus", .devotion), ("Três Ave-Marias", .devotion),
        ("Oração mental", .mentalPrayer), ("Leitura espiritual", .spiritualReading), ("Evangelho do dia", .gospel),
        ("Exame de consciência", .examination), ("Missa", .free), ("Visita ao Santíssimo", .free),
        ("Visita a enfermos", .free), ("Caridade", .free), ("Confissão", .free), ("Atividade personalizada", .free)
    ]
    var body: some View {
        NavigationStack {
            List {
                Section { Text("Escolha um ponto de partida. Cada bloco pode ter seus próprios textos, perguntas e horários.").foregroundStyle(.secondary) }
                ForEach(entries.indices, id: \.self) { i in
                    Button {
                        var activity = Activity(name: entries[i].0, kind: entries[i].1, momentID: moment.id, position: Int.max)
                        if activity.kind == .examination { activity.questions = Editorial.examinations[0].copyQuestions() }
                        if activity.name == "Três Ave-Marias" { activity.supportText = Array(repeating: Editorial.hailMary, count: 3).joined(separator: "\n\n") }
                        draft = activity
                    } label: { Label(entries[i].0, systemImage: entries[i].1.symbol).padding(.vertical, 6) }
                }
            }.navigationTitle("Adicionar prática").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fechar") { dismiss() } } }
                .sheet(item: $draft) { ActivityEditor(activity: $0, onSaved: { dismiss() }).protectedContent() }
        }
    }
}
