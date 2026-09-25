import Foundation
import Observation

struct SourceRecord: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var title: String
    var bookmark: Data
    var isLocked: Bool
    var addedAt: Date

    init(id: UUID = UUID(), title: String, bookmark: Data, isLocked: Bool = false, addedAt: Date = .now) {
        self.id = id
        self.title = title
        self.bookmark = bookmark
        self.isLocked = isLocked
        self.addedAt = addedAt
    }
}

@MainActor
@Observable
final class LibraryStore {
    private(set) var sources: [SourceRecord] = []
    var lastError: String?

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL()
        load()
    }

    var visibleSources: [SourceRecord] {
        sources.filter { !$0.isLocked }
    }

    func add(url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        do {
            let bookmark = try url.bookmarkData(
                options: [],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            let record = SourceRecord(title: url.lastPathComponent, bookmark: bookmark)
            sources.append(record)
            save()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func remove(_ source: SourceRecord) {
        sources.removeAll { $0.id == source.id }
        save()
    }

    func setLocked(_ locked: Bool, source: SourceRecord) {
        guard let index = sources.firstIndex(where: { $0.id == source.id }) else { return }
        sources[index].isLocked = locked
        save()
    }

    func resolvedURL(for source: SourceRecord) -> URL? {
        var stale = false
        guard let url = try? URL(
            resolvingBookmarkData: source.bookmark,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &stale
        ) else {
            lastError = "Không mở được thư mục \(source.title)."
            return nil
        }
        if stale {
            add(url: url)
        }
        return url
    }

    func contents(of source: SourceRecord) -> [LocalMedia] {
        guard let url = resolvedURL(for: source) else { return [] }
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        return LocalFolderReader.read(root: url)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        sources = (try? JSONDecoder().decode([SourceRecord].self, from: data)) ?? []
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(sources)
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: fileURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private static func defaultFileURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base.appendingPathComponent("Meine/sources.json")
    }
}
