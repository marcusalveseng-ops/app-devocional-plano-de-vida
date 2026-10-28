import Foundation
import Combine
import DevotionalCore

@MainActor
final class GospelService: ObservableObject {
    @Published private(set) var content: GospelContent?
    @Published private(set) var loading = false
    @Published private(set) var message: String?
    @Published private(set) var usingCache = false
    private let client: GospelClient
    private let cacheURL: URL
    private var generation = UUID()
    var isConfigured: Bool { client.configuration?.licenseConfirmed == true }
    var audioAllowed: Bool { client.configuration?.audioAllowed == true }
    init() {
        let info = Bundle.main.infoDictionary ?? [:]
        if let endpoint = info["GospelEndpoint"] as? String, let url = URL(string: endpoint), url.scheme == "https",
           let edition = info["GospelEdition"] as? String, !edition.isEmpty {
            client = GospelClient(configuration: GospelConfiguration(endpoint: url, edition: edition,
                licenseConfirmed: info["GospelLicenseConfirmed"] as? Bool ?? false,
                audioAllowed: info["GospelAudioAllowed"] as? Bool ?? false,
                cacheAllowed: info["GospelCacheAllowed"] as? Bool ?? false))
        } else { client = GospelClient(configuration: nil) }
        cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("gospel-authorized.json")
        if client.configuration?.cacheAllowed != true { try? FileManager.default.removeItem(at: cacheURL) }
    }
    func load(day: String) async {
        let token = UUID(); generation = token; loading = true; content = nil; message = nil; usingCache = false
        if let config = client.configuration, config.licenseConfirmed, config.cacheAllowed,
           let bytes = try? Data(contentsOf: cacheURL), let saved = try? JSONDecoder().decode(GospelContent.self, from: bytes),
           (try? saved.validate(for: day, edition: config.edition)) != nil {
            content = saved; usingCache = true
        }
        do {
            let loaded = try await client.fetch(day: day, session: URLSession(configuration: .ephemeral))
            guard generation == token else { return }
            content = loaded; usingCache = false
            if client.configuration?.cacheAllowed == true, let data = try? JSONEncoder().encode(loaded) {
                try? data.write(to: cacheURL, options: [.atomic, .completeFileProtection])
            }
        } catch {
            guard generation == token else { return }
            message = content == nil ? (error is GospelError ? error.localizedDescription : GospelError.unavailable.localizedDescription) : "Sem conexão com a fonte. Exibindo a cópia desta mesma data salva neste iPhone."
        }
        loading = false
    }
}
