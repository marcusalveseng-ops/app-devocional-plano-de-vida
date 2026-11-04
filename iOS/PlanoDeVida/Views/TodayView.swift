import SwiftUI
import DevotionalCore

struct TodayView: View {
    @EnvironmentObject var model: AppModel
    private let clock = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(Date(), format: .dateTime.weekday(.wide).day().month(.wide)).font(.subheadline).foregroundStyle(Palette.forest)
                    Text("Um dia de cada vez.").font(.system(.largeTitle, design: .serif))
                    Text("Seu plano para hoje").foregroundStyle(.secondary)
                }.padding(.top, 8)
                if model.state.activities.filter({ $0.isScheduled(on: Date()) }).isEmpty {
                    ContentUnavailableView("Um dia em aberto", systemImage: "sun.horizon", description: Text("Adicione suas práticas em Meu plano ou escolha os dias em que deseja realizá-las."))
                }
                ForEach(model.state.moments) { moment in
                    let activities = model.state.orderedActivities(in: moment.id).filter { $0.isScheduled(on: Date()) }
                    if !activities.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(moment.name).font(.title3.weight(.semibold)).accessibilityAddTraits(.isHeader)
                            VStack(spacing: 0) {
                                ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                                    ActivityCard(activity: activity)
                                    if index < activities.count - 1 {
                                        Rectangle().fill(Palette.forest.opacity(0.2)).frame(width: 2, height: 14).frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 29).accessibilityHidden(true)
                                    }
                                }
                            }
                        }
                    }
                }
                Text("Você pode abrir qualquer prática, na ordem que fizer sentido hoje.").font(.footnote).foregroundStyle(.secondary).padding(.bottom, 20)
            }.padding(.horizontal, 22).frame(maxWidth: 600)
        }.background(Palette.canvas).navigationTitle("Hoje").navigationBarTitleDisplayMode(.inline)
            .onReceive(clock) { _ in model.today = LocalDay.string() }
    }
}

struct ActivityCard: View {
    @EnvironmentObject var model: AppModel
    let activity: Activity
    var body: some View {
        HStack(spacing: 8) {
            Button { model.openActivity(activity.id) } label: {
                HStack(spacing: 14) {
                    Image(systemName: activity.kind.symbol).font(.title2).foregroundStyle(Palette.forest)
                        .frame(width: 42, height: 48).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(activity.name).font(.headline).foregroundStyle(.primary).multilineTextAlignment(.leading)
                        HStack(spacing: 10) {
                            if let reminder = activity.reminder { Label(reminder.display, systemImage: "bell") }
                            if let minutes = activity.durationMinutes, activity.kind.supportsTimer { Text("\(minutes) min") }
                            if activity.kind == .examination { Text("Reflexão guiada") }
                            if activity.kind == .gospel { Text("Leitura e escuta") }
                        }.font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }.padding(.vertical, 16).padding(.leading, 12).contentShape(Rectangle())
            }.buttonStyle(.plain)
            Button { model.toggleCompletion(activity.id) } label: {
                Image(systemName: model.state.completed(activity.id, on: model.today) ? "checkmark.circle.fill" : "circle")
                    .font(.title2).foregroundStyle(model.state.completed(activity.id, on: model.today) ? Palette.forest : .secondary)
                    .frame(width: 48, height: 52)
            }.buttonStyle(.plain).padding(.trailing, 6)
                .accessibilityLabel(model.state.completed(activity.id, on: model.today) ? "Desmarcar \(activity.name)" : "Marcar \(activity.name) como realizada")
        }.background(Palette.card, in: RoundedRectangle(cornerRadius: 20))
    }
}
