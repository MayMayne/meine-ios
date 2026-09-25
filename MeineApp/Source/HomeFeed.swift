import Foundation

enum ContentKind: String, Codable, Sendable, CaseIterable {
    case video
    case music
    case comic
    case novel
    case short
    case unknown

    init(folderHint: String) {
        switch folderHint.lowercased() {
        case "video", "videos", "movie", "movies", "phim": self = .video
        case "music", "audio", "nhac": self = .music
        case "comic", "comics", "manga", "truyen-tranh": self = .comic
        case "novel", "novels", "book", "books", "truyen-chu": self = .novel
        case "short", "shorts": self = .short
        default: self = .unknown
        }
    }

    var title: String {
        switch self {
        case .video: "Phim"
        case .music: "Nhạc"
        case .comic: "Truyện tranh"
        case .novel: "Truyện chữ"
        case .short: "Video ngắn"
        case .unknown: "Khác"
        }
    }
}

enum HomeSectionKind: String, Codable, Sendable {
    case carousel
    case grid
    case horizontalCardStrip = "horizontal_card_strip"
    case rankList = "rank_list"
    case compactList = "compact_list"
}

struct HomeFeed: Codable, Sendable, Equatable {
    var sourceId: String
    var version: String
    var title: String
    var themeOverrides: ThemeOverrides?
    var sections: [HomeSection]

    struct ThemeOverrides: Codable, Sendable, Equatable {
        var primaryColor: String?
        var backgroundColor: String?
    }
}

struct HomeSection: Codable, Sendable, Equatable, Identifiable {
    var id: String
    var type: HomeSectionKind
    var title: String?
    var aspectRatio: String?
    var autoScrollInterval: Double?
    var columns: Int?
    var seeMoreURL: String?
    var items: [HomeItem]

    enum CodingKeys: String, CodingKey {
        case id, type, title, aspectRatio, autoScrollInterval, columns, items
        case seeMoreURL = "seeMoreUrl"
    }
}

struct HomeItem: Codable, Sendable, Equatable, Identifiable {
    var id: String
    var contentType: ContentKind
    var title: String
    var subtitle: String?
    var coverURL: String?
    var actionURL: String
    var badge: String?
    var rank: Int?

    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, badge, rank
        case contentType
        case coverURL = "coverUrl"
        case actionURL = "actionUrl"
    }
}

enum MeineLink: Equatable, Sendable {
    case content(ContentKind, String)
    case category(String)
    case unsupported(String)

    init(url: String) {
        guard url.hasPrefix("meine://") else {
            self = .unsupported(url)
            return
        }
        let parts = url.dropFirst("meine://".count).split(separator: "/").map(String.init)
        if parts.count >= 3, parts[0] == "content", let kind = ContentKind(rawValue: parts[1]) {
            self = .content(kind, parts[2])
        } else if parts.count >= 2, parts[0] == "category" {
            self = .category(parts[1])
        } else {
            self = .unsupported(url)
        }
    }
}
