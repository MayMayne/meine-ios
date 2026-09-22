import SwiftUI

struct InstalledSource: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var rootPath: String
}

@MainActor
final class AppModel: ObservableObject {
    @Published var sources: [InstalledSource] = []
    @Published var library: [LibraryEntry] = []
    @Published var lists: [UserList] = []
    @Published var notes: [ReaderNote] = []
    @Published var addressBook: [AddressRow] = []
    @Published var settings: AppSettings = .builtIn
    @Published var unlocked: Set<String> = []

    var palette: Palette { Palette.from(settings) }

    init() {
        library = LibraryStore.loadLibrary()
        lists = LibraryStore.loadLists()
        notes = LibraryStore.loadNotes()
        addressBook = LibraryStore.loadAddress()
        settings = LibraryStore.loadSettings()
        if let data = try? Data(contentsOf: indexURL()),
           let rows = try? JSONDecoder().decode([InstalledSource].self, from: data) {
            sources = rows
        }
    }

    func remember(url: URL, manifest: SourceManifest) {
        let row = InstalledSource(id: manifest.id, name: manifest.name, rootPath: url.path)
        sources.removeAll { $0.id == row.id }
        sources.append(row)
        if let data = try? JSONEncoder().encode(sources) {
            try? data.write(to: indexURL(), options: .atomic)
        }
        BookmarkStore.save(url: url, sourceID: manifest.id)
        if !SourceLock.hasLock(sourceID: manifest.id) {
            unlocked.insert(manifest.id)
        }
    }

    func root(for source: InstalledSource) -> URL? {
        if let saved = BookmarkStore.resolve(sourceID: source.id) { return saved }
        let url = URL(fileURLWithPath: source.rootPath, isDirectory: true)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func addToLibrary(_ item: CatalogItem, sourceID: String) {
        let entry = LibraryEntry(
            ref: item.ref,
            sourceID: sourceID,
            title: item.title,
            kind: item.kind.rawValue,
            addedAt: Date()
        )
        library.removeAll { $0.id == entry.id }
        library.insert(entry, at: 0)
        LibraryStore.saveLibrary(library)
    }

    func saveSettings() { LibraryStore.saveSettings(settings) }
    func saveLists() { LibraryStore.saveLists(lists) }
    func saveNotes() { LibraryStore.saveNotes(notes) }
    func saveAddress() { LibraryStore.saveAddress(addressBook) }

    private func indexURL() -> URL {
        LibraryStore.supportDirectory().appendingPathComponent("sources.json")
    }
}
