import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import DevotionalCore

private final class FixtureProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (Int, Data))?
    override class func canInit(with request: URLRequest) -> Bool { request.url?.host == "gospel.test.invalid" }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            let (status, data) = try Self.handler!(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() {}
}

final class GospelNetworkTests: XCTestCase {
    private var session: URLSession!
    private let client = GospelClient(configuration: GospelConfiguration(endpoint: URL(string: "https://gospel.test.invalid/daily")!, edition: "fixture-only", licenseConfirmed: true, audioAllowed: true, cacheAllowed: false))
    override func setUp() {
        let config = URLSessionConfiguration.ephemeral; config.protocolClasses = [FixtureProtocol.self]
        session = URLSession(configuration: config)
    }
    override func tearDown() { session.invalidateAndCancel(); FixtureProtocol.handler = nil }
    func testRequestedDateAndEditionAreSentWithoutPersonalData() async throws {
        let data = try response(day: "2026-11-01")
        FixtureProtocol.handler = { request in
            let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems!
            XCTAssertEqual(Set(items.map(\.name)), ["date", "calendar", "edition"])
            XCTAssertEqual(items.first { $0.name == "date" }?.value, "2026-11-01")
            XCTAssertEqual(items.first { $0.name == "calendar" }?.value, "roman-br")
            XCTAssertEqual(items.first { $0.name == "edition" }?.value, "fixture-only")
            XCTAssertNil(request.httpBody)
            return (200, data)
        }
        let content = try await client.fetch(day: "2026-11-01", session: session)
        XCTAssertEqual(content.date, "2026-11-01")
    }
    func testWrongDateIsRejectedThroughHTTPPath() async throws {
        let data = try response(day: "2026-11-01")
        FixtureProtocol.handler = { _ in (200, data) }
        do { _ = try await client.fetch(day: "2026-11-02", session: session); XCTFail("Old date must not be displayed as today") }
        catch { XCTAssertEqual(error.localizedDescription, GospelError.wrongDate.localizedDescription) }
    }
    func testEmptyResponseIsRejected() async {
        FixtureProtocol.handler = { _ in (200, Data()) }
        do { _ = try await client.fetch(day: "2026-11-01", session: session); XCTFail("Empty response must not succeed") }
        catch { XCTAssertEqual(error.localizedDescription, GospelError.invalidContent.localizedDescription) }
    }
    func testNetworkFailureThenRecovery() async throws {
        FixtureProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }
        do { _ = try await client.fetch(day: "2026-11-01", session: session); XCTFail("Offline request must fail") }
        catch { XCTAssertTrue(error is URLError) }
        let data = try response(day: "2026-11-01")
        FixtureProtocol.handler = { _ in (200, data) }
        let content = try await client.fetch(day: "2026-11-01", session: session)
        XCTAssertEqual(content.date, "2026-11-01")
    }
    func testServiceFailureIsNotParsedAsContent() async {
        FixtureProtocol.handler = { _ in (503, Data("temporarily unavailable".utf8)) }
        do { _ = try await client.fetch(day: "2026-11-01", session: session); XCTFail("503 must fail") }
        catch { XCTAssertEqual(error.localizedDescription, GospelError.unavailable.localizedDescription) }
    }
    private func response(day: String) throws -> Data {
        try JSONEncoder().encode(GospelContent(date: day, calendar: "roman-br", edition: "fixture-only", reference: "Referência artificial de teste", text: "Fixture de contrato. Não é uma passagem bíblica.", sourceName: "Teste local", sourceURL: URL(string: "https://gospel.test.invalid/source")!))
    }
}
