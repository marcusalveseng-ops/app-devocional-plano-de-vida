import SwiftUI
import DevotionalCore

@main
struct PlanoDeVidaApp: App {
    @StateObject private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(model).tint(Palette.forest)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { model.foreground() } else { model.conceal() }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in model.foreground() }
                .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in model.foreground() }
                .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in model.foreground() }
        }
    }
}

enum Palette {
    static let forest = Color(red: 0.18, green: 0.36, blue: 0.29)
    static let terracotta = Color(red: 0.64, green: 0.34, blue: 0.22)
    static let canvas = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
}

struct RootView: View {
    @EnvironmentObject var model: AppModel
    @State private var tab = 0
    @State private var path: [UUID] = []
    var body: some View {
        Group {
            if model.loadFailed {
                ContentUnavailableView("Seus dados foram preservados", systemImage: "lock.doc", description: Text(model.errorMessage ?? "Não foi possível abrir o plano."))
            } else if !model.state.hasOnboarded {
                WelcomeView()
            } else {
                NavigationStack(path: $path) {
                    TabView(selection: $tab) {
                        TodayView().tabItem { Label("Hoje", systemImage: "sun.max") }.tag(0)
                        PlanView().tabItem { Label("Meu plano", systemImage: "square.stack.3d.up") }.tag(1)
                        SettingsView().tabItem { Label("Ajustes", systemImage: "slider.horizontal.3") }.tag(2)
                    }
                    .navigationDestination(for: UUID.self) { ActivityView(activityID: $0) }
                    .safeAreaInset(edge: .bottom, spacing: 0) { AudioBanner(player: model.audio) }
                }
                .onChange(of: model.selectedActivity) { _, id in
                    if let id { path = [id]; model.selectedActivity = nil }
                }
            }
        }
        .protectedContent()
        .alert("Não foi possível concluir", isPresented: Binding(get: { model.errorMessage != nil && !model.loadFailed }, set: { if !$0 { model.errorMessage = nil } })) {
            Button("Entendi") { model.errorMessage = nil }
        } message: { Text(model.errorMessage ?? "") }
        .task { model.foreground() }
    }
}

struct ProtectionModifier: ViewModifier {
    @EnvironmentObject var model: AppModel
    func body(content: Content) -> some View {
        content
            .opacity(model.privacyShield || model.isLocked ? 0 : 1)
            .accessibilityHidden(model.privacyShield || model.isLocked)
            .overlay {
                if model.privacyShield || model.isLocked {
                    ZStack {
                        Palette.canvas.ignoresSafeArea()
                        VStack(spacing: 24) {
                            Image(systemName: "leaf.circle").font(.system(size: 68, weight: .ultraLight)).foregroundStyle(Palette.forest)
                            Text("Plano de Vida").font(.largeTitle.bold())
                            if model.isLocked && !model.privacyShield {
                                Text("Um espaço só seu.").foregroundStyle(.secondary)
                                Button { Task { await model.unlock() } } label: { Label("Desbloquear", systemImage: "lock.open").frame(maxWidth: .infinity) }
                                    .buttonStyle(.borderedProminent).disabled(model.authenticating)
                                if let message = model.authenticationMessage { Text(message).font(.footnote).foregroundStyle(.secondary) }
                            }
                        }.padding(32).frame(maxWidth: 440)
                    }
                }
            }
            .transaction { transaction in if model.privacyShield || model.isLocked { transaction.animation = nil } }
    }
}
extension View { func protectedContent() -> some View { modifier(ProtectionModifier()) } }

struct WelcomeView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Image(systemName: "leaf.circle").font(.system(size: 88, weight: .ultraLight)).foregroundStyle(Palette.forest).padding(.top, 44)
                Text("Plano de Vida").font(.system(.largeTitle, design: .serif).bold())
                Text("Encontre espaço para\no que permanece.").font(.system(.title, design: .serif))
                Text("Organize suas práticas nos momentos do dia. Leia, escute e reflita no seu ritmo.").font(.title3).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 18) {
                    Label("Um plano que se adapta à sua rotina", systemImage: "square.stack.3d.up")
                    Label("Orações e reflexão, também sem internet", systemImage: "book")
                    Label("Anotações guardadas neste iPhone", systemImage: "lock")
                }.font(.subheadline)
                VStack(spacing: 12) {
                    Button("Começar com um modelo") { model.onboard(useTemplate: true) }.buttonStyle(PrimaryButtonStyle()).accessibilityIdentifier("onboard-template")
                    Button("Criar meu próprio plano") { model.onboard(useTemplate: false) }.buttonStyle(.bordered).frame(maxWidth: .infinity)
                }
                Text("Sem cadastro. Os dados ficam somente neste iPhone e não fazem parte de um backup do app ou do iCloud. Apagar o app ou perder o aparelho pode apagar seu plano e suas notas.")
                    .font(.footnote).foregroundStyle(.secondary)
            }.padding(28).frame(maxWidth: 540)
        }.background(Palette.canvas)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).frame(maxWidth: .infinity).padding(.vertical, 16).padding(.horizontal)
            .foregroundStyle(.white).background(Palette.forest.opacity(configuration.isPressed ? 0.8 : 1), in: RoundedRectangle(cornerRadius: 18))
    }
}

struct AudioBanner: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject var player: SpeechPlayer
    var body: some View {
        if player.isActive {
            HStack(spacing: 16) {
                Button { if let id = player.activityID { model.openActivity(id) } } label: {
                    Label("Momento de reflexão", systemImage: "waveform").font(.subheadline)
                }
                Spacer(minLength: 0)
                Button { if player.phase == .paused { player.resume() } else { player.pause() } } label: {
                    Image(systemName: player.phase == .paused ? "play.fill" : "pause.fill").frame(width: 44, height: 44)
                }.accessibilityLabel(player.phase == .paused ? "Retomar áudio" : "Pausar áudio")
                Button { player.stop() } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }.accessibilityLabel("Encerrar áudio")
            }.padding(.leading, 18).padding(.trailing, 6).background(.regularMaterial)
        }
    }
}
