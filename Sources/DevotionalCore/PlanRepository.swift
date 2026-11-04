import Foundation

/// One versioned atomic document. A decode failure never silently replaces user data.
public final class PlanRepository {
    public let fileURL: URL
    public init(fileURL: URL) { self.fileURL = fileURL }
    public func load() throws -> PlanState {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return PlanState() }
        let data = try Data(contentsOf: fileURL)
        let version = try JSONDecoder().decode(Version.self, from: data)
        guard version.schemaVersion == 1 else { throw PlanError.unsupportedVersion }
        let state = try JSONDecoder().decode(PlanState.self, from: data)
        try state.validate()
        return state
    }
    public func save(_ state: PlanState) throws {
        try state.validate()
        let parent = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(state)
        #if os(iOS)
        var directory = parent
        var values = URLResourceValues(); values.isExcludedFromBackup = true
        try directory.setResourceValues(values)
        try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        var file = fileURL
        try file.setResourceValues(values)
        #else
        try data.write(to: fileURL, options: .atomic)
        #endif
    }
    private struct Version: Decodable { var schemaVersion: Int }
}
