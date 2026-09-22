import Foundation

struct UserList: Codable, Equatable, Identifiable {
    var id: UUID
    var title: String
    var kind: String
    var isPublic: Bool
    var refs: [String]
}

struct LibraryEntry: Codable, Equatable, Identifiable {
    var ref: String
    var sourceID: String
    var title: String
    var kind: String
    var addedAt: Date
    var id: String { "\(sourceID)|\(ref)" }
}

struct ReaderNote: Codable, Equatable, Identifiable {
    var id: UUID
    var kind: String
    var source: String
    var wrong: String
    var corrected: String
}

struct AddressRow: Codable, Equatable, Identifiable {
    var id: UUID
    var source: String
    var preferred: String
    var pronoun: String
}

struct AppSettings: Codable, Equatable {
    var backgroundHex: String
    var cardHex: String
    var accentHex: String
    var inkHex: String
    var intensity: Double
    var textIntensity: Double
    var fontName: String
    var fontScale: Double
    var readerMode: String
    var autoScrollSpeed: Double
    var lyricStage: String
    var eqGains: [Double]
    var comicMode: String
    var comicMargin: Double
    var tapZone: String
    var sleepMinutes: Int
    var translationPrompt: String

    static let builtIn = AppSettings(
        backgroundHex: MeineThemeDefault.background,
        cardHex: MeineThemeDefault.card,
        accentHex: MeineThemeDefault.accent,
        inkHex: MeineThemeDefault.onBackground,
        intensity: 0.35,
        textIntensity: 0.8,
        fontName: "System",
        fontScale: 1,
        readerMode: "scroll",
        autoScrollSpeed: 0.4,
        lyricStage: "half",
        eqGains: Array(repeating: 0, count: 10),
        comicMode: "webtoon",
        comicMargin: 0,
        tapZone: "sides",
        sleepMinutes: 0,
        translationPrompt: "Dịch tự nhiên sang tiếng Việt, giữ ngôi xưng trong bảng, tránh lỗi đã ghi."
    )
}

enum LibraryStore {
    static func supportDirectory() -> URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = root.appendingPathComponent("Meine", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func loadLibrary() -> [LibraryEntry] { load("library.json", fallback: []) }
    static func saveLibrary(_ rows: [LibraryEntry]) { save("library.json", rows) }
    static func loadLists() -> [UserList] { load("lists.json", fallback: []) }
    static func saveLists(_ rows: [UserList]) { save("lists.json", rows) }
    static func loadNotes() -> [ReaderNote] { load("notes.json", fallback: []) }
    static func saveNotes(_ rows: [ReaderNote]) { save("notes.json", rows) }
    static func loadAddress() -> [AddressRow] { load("address.json", fallback: []) }
    static func saveAddress(_ rows: [AddressRow]) { save("address.json", rows) }
    static func loadSettings() -> AppSettings { load("settings.json", fallback: .builtIn) }
    static func saveSettings(_ value: AppSettings) { save("settings.json", value) }

    private static func load<T: Decodable>(_ name: String, fallback: T) -> T {
        let url = supportDirectory().appendingPathComponent(name)
        guard let data = try? Data(contentsOf: url),
              let value = try? JSONDecoder().decode(T.self, from: data) else { return fallback }
        return value
    }

    private static func save<T: Encodable>(_ name: String, _ value: T) {
        let url = supportDirectory().appendingPathComponent(name)
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
