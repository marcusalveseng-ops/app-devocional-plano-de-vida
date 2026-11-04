import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct GospelContent: Codable, Equatable {
    public let date: String
    public let calendar: String
    public let edition: String
    public let reference: String
    public let text: String
    public let sourceName: String
    public let sourceURL: URL
    public init(date: String, calendar: String, edition: String, reference: String, text: String, sourceName: String, sourceURL: URL) {
        self.date = date; self.calendar = calendar; self.edition = edition; self.reference = reference
        self.text = text; self.sourceName = sourceName; self.sourceURL = sourceURL
    }
    public func validate(for day: String, edition expectedEdition: String) throws {
        guard date == day else { throw GospelError.wrongDate }
        guard calendar == "roman-br", edition == expectedEdition,
              !reference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !sourceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              sourceURL.scheme == "https", sourceURL.host != nil else { throw GospelError.invalidContent }
    }
}

public struct GospelConfiguration {
    public let endpoint: URL
    public let edition: String
    public let licenseConfirmed: Bool
    public let audioAllowed: Bool
    public let cacheAllowed: Bool
    public init(endpoint: URL, edition: String, licenseConfirmed: Bool, audioAllowed: Bool, cacheAllowed: Bool) {
        self.endpoint = endpoint; self.edition = edition; self.licenseConfirmed = licenseConfirmed
        self.audioAllowed = audioAllowed; self.cacheAllowed = cacheAllowed
    }
}

public enum GospelError: LocalizedError {
    case notConfigured, wrongDate, invalidContent, unavailable
    public var errorDescription: String? {
        switch self {
        case .notConfigured: return "A fonte do Evangelho está em preparação. O texto será disponibilizado após a autorização de uso."
        case .wrongDate: return "A fonte retornou uma leitura de outra data. Tente novamente mais tarde."
        case .invalidContent: return "A fonte retornou um conteúdo incompleto ou uma edição diferente da prevista."
        case .unavailable: return "Não foi possível obter o Evangelho desta data. Verifique a conexão e tente novamente."
        }
    }
}

public struct GospelClient {
    public let configuration: GospelConfiguration?
    public init(configuration: GospelConfiguration?) { self.configuration = configuration }
    public func fetch(day: String, session: URLSession = .shared) async throws -> GospelContent {
        guard let config = configuration, config.licenseConfirmed,
              config.endpoint.scheme == "https", config.endpoint.host != nil, !config.edition.isEmpty else { throw GospelError.notConfigured }
        var components = URLComponents(url: config.endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = (components.queryItems ?? []).filter { !["date", "calendar", "edition"].contains($0.name) }
            + [URLQueryItem(name: "date", value: day), URLQueryItem(name: "calendar", value: "roman-br"), URLQueryItem(name: "edition", value: config.edition)]
        guard let url = components.url else { throw GospelError.notConfigured }
        var request = URLRequest(url: url, timeoutInterval: 20)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200, data.count <= 1_000_000 else { throw GospelError.unavailable }
        let content: GospelContent
        do { content = try JSONDecoder().decode(GospelContent.self, from: data) } catch { throw GospelError.invalidContent }
        try content.validate(for: day, edition: config.edition)
        return content
    }
}
