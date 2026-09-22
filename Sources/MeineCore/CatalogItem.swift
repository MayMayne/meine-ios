import Foundation

struct MediaRef: Equatable, Codable {
    var href: String
    var mime: String?
}

struct SubtitleTrack: Equatable, Identifiable {
    var id: String
    var language: String
    var label: String
    var href: String
    var mime: String?
    var isDefault: Bool
    var kind: String
}

struct LyricTrack: Equatable, Identifiable {
    var id: String
    var format: String
    var language: String
    var href: String
    var synced: Bool
    var isDefault: Bool
}

struct EpisodeRef: Equatable, Identifiable {
    var id: String
    var title: String
    var duration: Double?
    var media: MediaRef?
    var subtitles: [SubtitleTrack]
}

struct SeasonRef: Equatable, Identifiable {
    var id: String
    var title: String
    var episodes: [EpisodeRef]
}

struct ChapterRef: Equatable, Identifiable {
    var id: String
    var title: String
    var href: String?
    var mime: String?
    var pages: [PageRef]
}

struct PageRef: Equatable {
    var href: String
    var width: Int?
    var height: Int?
}

struct AddressHint: Equatable {
    var source: String
    var preferred: String
    var pronoun: String
}

struct CatalogItem: Equatable, Identifiable {
    var ref: String
    var kind: ContentKind
    var title: String
    var subtitle: String?
    var summary: String?
    var artwork: String?
    var artists: [String]
    var authors: [String]
    var creator: String?
    var duration: Double?
    var media: MediaRef?
    var subtitles: [SubtitleTrack]
    var lyrics: [LyricTrack]
    var seasons: [SeasonRef]
    var chapters: [ChapterRef]
    var feed: String?
    var genres: [String]
    var defaultReading: String?
    var addressHints: [AddressHint]
    var genreHint: String?

    var id: String { ref }

    var playableMedia: MediaRef? {
        if let media { return media }
        return seasons.first?.episodes.first?.media
    }

    func resolved(against card: HomeCard) -> CatalogItem {
        var copy = self
        if copy.title.isEmpty { copy.title = card.title ?? ref }
        if copy.artwork == nil { copy.artwork = card.artwork }
        return copy
    }

    static func placeholder(card: HomeCard) -> CatalogItem {
        CatalogItem(
            ref: card.ref,
            kind: card.kind ?? .movie,
            title: card.title ?? card.ref,
            subtitle: nil,
            summary: "Chưa có file chi tiết trong catalog. Thêm item đầy đủ vào home.json.",
            artwork: card.artwork,
            artists: [],
            authors: [],
            creator: nil,
            duration: nil,
            media: nil,
            subtitles: [],
            lyrics: [],
            seasons: [],
            chapters: [],
            feed: nil,
            genres: [],
            defaultReading: nil,
            addressHints: [],
            genreHint: nil
        )
    }
}

enum CatalogParser {
    static func items(in pageObject: [String: Any]) -> [String: CatalogItem] {
        guard let map = pageObject["items"] as? [String: Any] else { return [:] }
        var parsed: [String: CatalogItem] = [:]
        for (ref, raw) in map {
            guard let object = raw as? [String: Any],
                  let item = item(ref: ref, object: object) else { continue }
            parsed[ref] = item
        }
        return parsed
    }

    static func items(from data: Data) -> [String: CatalogItem] {
        guard let json = try? JSONSerialization.jsonObject(with: data),
              let object = json as? [String: Any] else { return [:] }
        if let map = object["items"] as? [String: Any] {
            return items(in: object)
        }
        if let rows = object["items"] as? [[String: Any]] {
            var parsed: [String: CatalogItem] = [:]
            for row in rows {
                guard let ref = row["ref"] as? String, let item = item(ref: ref, object: row) else { continue }
                parsed[ref] = item
            }
            return parsed
        }
        return [:]
    }

    static func item(ref: String, object: [String: Any]) -> CatalogItem? {
        guard let kindName = object["kind"] as? String,
              let kind = ContentKind(rawValue: kindName) else { return nil }
        let title = (object["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let title, !title.isEmpty else { return nil }
        let hints = object["translationHints"] as? [String: Any]
        let book = hints?["addressBook"] as? [[String: Any]] ?? []
        return CatalogItem(
            ref: ref,
            kind: kind,
            title: title,
            subtitle: object["subtitle"] as? String,
            summary: object["summary"] as? String,
            artwork: object["artwork"] as? String,
            artists: object["artists"] as? [String] ?? [],
            authors: object["authors"] as? [String] ?? [],
            creator: object["creator"] as? String,
            duration: number(object["duration"]),
            media: media(object["media"]),
            subtitles: subtitles(object["subtitles"]),
            lyrics: lyrics(object["lyrics"]),
            seasons: seasons(object["seasons"]),
            chapters: chapters(object["chapters"]),
            feed: object["feed"] as? String,
            genres: object["genres"] as? [String] ?? [],
            defaultReading: object["defaultReading"] as? String,
            addressHints: book.compactMap { row in
                guard let source = row["source"] as? String,
                      let preferred = row["preferred"] as? String else { return nil }
                return AddressHint(source: source, preferred: preferred, pronoun: row["pronoun"] as? String ?? "")
            },
            genreHint: hints?["genre"] as? String
        )
    }

    private static func media(_ raw: Any?) -> MediaRef? {
        guard let object = raw as? [String: Any], let href = object["href"] as? String, Href.isAllowed(href) else {
            return nil
        }
        return MediaRef(href: href, mime: object["mime"] as? String)
    }

    private static func subtitles(_ raw: Any?) -> [SubtitleTrack] {
        guard let rows = raw as? [[String: Any]] else { return [] }
        return rows.compactMap { row in
            guard let id = row["id"] as? String, let href = row["href"] as? String, Href.isAllowed(href) else {
                return nil
            }
            return SubtitleTrack(
                id: id,
                language: row["language"] as? String ?? "und",
                label: row["label"] as? String ?? id,
                href: href,
                mime: row["mime"] as? String,
                isDefault: row["default"] as? Bool ?? false,
                kind: row["kind"] as? String ?? "soft"
            )
        }
    }

    private static func lyrics(_ raw: Any?) -> [LyricTrack] {
        guard let rows = raw as? [[String: Any]] else { return [] }
        return rows.compactMap { row in
            guard let href = row["href"] as? String, Href.isAllowed(href) else { return nil }
            let id = row["id"] as? String ?? href
            return LyricTrack(
                id: id,
                format: (row["format"] as? String ?? "lrc").lowercased(),
                language: row["language"] as? String ?? "und",
                href: href,
                synced: row["synced"] as? Bool ?? false,
                isDefault: row["default"] as? Bool ?? false
            )
        }
    }

    private static func seasons(_ raw: Any?) -> [SeasonRef] {
        guard let rows = raw as? [[String: Any]] else { return [] }
        return rows.compactMap { row in
            guard let id = row["id"] as? String else { return nil }
            let episodes = (row["episodes"] as? [[String: Any]] ?? []).compactMap { ep -> EpisodeRef? in
                guard let eid = ep["id"] as? String else { return nil }
                return EpisodeRef(
                    id: eid,
                    title: ep["title"] as? String ?? eid,
                    duration: number(ep["duration"]),
                    media: media(ep["media"]),
                    subtitles: subtitles(ep["subtitles"])
                )
            }
            return SeasonRef(id: id, title: row["title"] as? String ?? id, episodes: episodes)
        }
    }

    private static func chapters(_ raw: Any?) -> [ChapterRef] {
        guard let rows = raw as? [[String: Any]] else { return [] }
        return rows.compactMap { row in
            guard let id = row["id"] as? String else { return nil }
            let pages = (row["pages"] as? [[String: Any]] ?? []).compactMap { page -> PageRef? in
                guard let href = page["href"] as? String, Href.isAllowed(href) else { return nil }
                return PageRef(href: href, width: page["width"] as? Int, height: page["height"] as? Int)
            }
            let href = row["href"] as? String
            let safeHref = href.flatMap { Href.isAllowed($0) ? $0 : nil }
            if pages.isEmpty && safeHref == nil { return nil }
            return ChapterRef(
                id: id,
                title: row["title"] as? String ?? id,
                href: safeHref,
                mime: row["mime"] as? String,
                pages: pages
            )
        }
    }

    private static func number(_ raw: Any?) -> Double? {
        if let value = raw as? Double { return value }
        if let value = raw as? Int { return Double(value) }
        return nil
    }
}
