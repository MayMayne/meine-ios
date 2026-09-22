import Foundation

enum MeineThemeDefault {
    static let background = "#E7F6F4"
    static let card = "#FFFFFF"
    static let accent = "#5BB8B0"
    static let onBackground = "#1B3331"
}

enum ContentKind: String, Codable, CaseIterable {
    case movie = "video.movie"
    case shortFilm = "video.shortFilm"
    case clip = "video.clip"
    case album = "video.album"
    case track = "audio.track"
    case comic = "comic.series"
    case book = "text.book"
}

enum CornerRadiusStyle: String, Codable {
    case sharp, soft, round
}

enum AuthMode: String, Codable {
    case none, password, bearer, connector
}

enum AuthScope: String, Codable {
    case app, bundle
}

enum CapabilityValue: String, Codable {
    case on, off, `default`
}

enum SectionType: String, Codable {
    case hero, rail, grid, list, `continue`, banner, genreChips, feed, spacer
}

enum CardStyle: String, Codable {
    case poster, square, wide, compact
}

struct SourceTheme: Codable, Equatable {
    var accent: String
    var background: String
    var onBackground: String
    var card: String
    var radius: CornerRadiusStyle

    static let meineDefault = SourceTheme(
        accent: MeineThemeDefault.accent,
        background: MeineThemeDefault.background,
        onBackground: MeineThemeDefault.onBackground,
        card: MeineThemeDefault.card,
        radius: .soft
    )

    /// Màu không hợp lệ bị bỏ. Chữ và nền quá gần thì nới chữ, không vẽ chữ mù.
    static func resolved(from raw: RawTheme?) -> SourceTheme {
        var theme = meineDefault
        guard let raw else { return theme }
        if let accent = HexColor.normalize(raw.accent) { theme.accent = accent }
        if let background = HexColor.normalize(raw.background) { theme.background = background }
        if let card = HexColor.normalize(raw.card) { theme.card = card }
        if let on = HexColor.normalize(raw.onBackground) { theme.onBackground = on }
        if let radius = raw.radius { theme.radius = radius }
        if HexColor.contrastRatio(theme.onBackground, theme.background) < 3 {
            theme.onBackground = HexColor.preferReadableInk(on: theme.background)
        }
        return theme
    }
}

struct RawTheme: Codable {
    var accent: String?
    var background: String?
    var onBackground: String?
    var card: String?
    var radius: CornerRadiusStyle?
}

struct SourceEndpoints: Codable, Equatable {
    var catalog: String
    var search: String?
    var resolve: String?
    var item: String?
    var mediaTemplate: String?

    var catalogIsRemote: Bool { Href.isAbsoluteHTTP(catalog) }
}

struct SourceAuth: Codable, Equatable {
    var mode: AuthMode
    var scope: AuthScope
    var hint: String?
    var keyId: String?
}

enum HomePointer: Equatable {
    case ref(String)
    case inline(HomePage)
    case tabs([SourceHomeTab])
}

struct SourceHomeTab: Codable, Equatable {
    var id: String
    var title: String
    var ref: String
}

struct SourceManifest: Equatable {
    var schemaVersion: Int
    var id: String
    var name: String
    var version: String
    var summary: String?
    var defaultLocale: String
    var kinds: [ContentKind]
    var home: HomePointer
    var endpoints: SourceEndpoints
    var theme: SourceTheme
    var capabilities: [String: CapabilityValue]
    var auth: SourceAuth
    var cacheTtl: Int
    var minAppVersion: String?
    var warnings: [String]
}

struct HomeCard: Equatable {
    var ref: String
    var kind: ContentKind?
    var title: String?
    var artwork: String?
}

struct HomeSection: Equatable, Identifiable {
    var id: String
    var type: SectionType
    var title: String?
    var subtitle: String?
    var items: [HomeCard]
    var cardStyle: CardStyle?
    var columns: Int?
    var body: String?
    var actionRef: String?
    var actionCatalog: String?
    var actionLabel: String?
    var tags: [String]
    var feed: String?
    var kinds: [ContentKind]
    var moreTitle: String?
    var moreCatalog: String?
    var spacerSize: String?
}

struct HomePage: Equatable {
    var schemaVersion: Int
    var title: String?
    var subtitle: String?
    var theme: SourceTheme?
    var sections: [HomeSection]
    var itemRefs: [String]
    var warnings: [String]
}

enum ManifestParseError: Error, Equatable, CustomStringConvertible {
    case notJSON
    case notObject
    case missing(String)
    case badID
    case badVersion
    case noKinds
    case homeMissing
    case tooManyTabs
    case catalogMissing

    var description: String {
        switch self {
        case .notJSON: return "JSON hỏng"
        case .notObject: return "manifest không phải object"
        case .missing(let key): return "thiếu \(key)"
        case .badID: return "id không hợp lệ"
        case .badVersion: return "schemaVersion không được hỗ trợ"
        case .noKinds: return "kinds rỗng hoặc không có loại nào app biết"
        case .homeMissing: return "home cần ref, inline hoặc tabs"
        case .tooManyTabs: return "home.tabs tối đa 6"
        case .catalogMissing: return "endpoints.catalog thiếu"
        }
    }
}
