import Foundation

struct HomeParseResult: Equatable {
    var page: HomePage
}

enum HomeParser {
    static func parse(_ data: Data) -> HomeParseResult {
        guard let json = try? JSONSerialization.jsonObject(with: data),
              let object = json as? [String: Any] else {
            return HomeParseResult(page: emptyPage(warnings: ["home JSON hỏng, hiện trang trống"]))
        }
        return parseObject(object)
    }

    static func parseObject(_ object: [String: Any]) -> HomeParseResult {
        var warnings: [String] = []
        let schema = object["schemaVersion"] as? Int ?? 1
        if schema != 1 {
            warnings.append("schemaVersion home lạ, vẫn thử đọc section")
        }
        let rawSections = object["sections"] as? [[String: Any]] ?? []
        var sections: [HomeSection] = []
        var seen = Set<String>()
        for raw in rawSections {
            guard let id = raw["id"] as? String, !id.isEmpty else {
                warnings.append("bỏ section không có id")
                continue
            }
            if !seen.insert(id).inserted {
                warnings.append("bỏ section trùng id \(id)")
                continue
            }
            guard let typeName = raw["type"] as? String, let type = SectionType(rawValue: typeName) else {
                warnings.append("bỏ section \(id) vì type lạ")
                continue
            }
            sections.append(section(id: id, type: type, raw: raw, warnings: &warnings))
        }
        let itemRefs = (object["items"] as? [String: Any])?.keys.sorted() ?? []
        let page = HomePage(
            schemaVersion: schema,
            title: object["title"] as? String,
            subtitle: object["subtitle"] as? String,
            theme: object["theme"] == nil ? nil : SourceTheme.resolved(from: rawTheme(object["theme"])),
            sections: sections,
            itemRefs: itemRefs,
            warnings: warnings
        )
        return HomeParseResult(page: page)
    }

    private static func section(
        id: String,
        type: SectionType,
        raw: [String: Any],
        warnings: inout [String]
    ) -> HomeSection {
        var columnCount = raw["columns"] as? Int
        if let value = columnCount, type != .list, value < 2 {
            warnings.append("section \(id) columns bị nâng lên 2")
            columnCount = 2
        }
        let action = raw["action"] as? [String: Any]
        let more = raw["more"] as? [String: Any]
        return HomeSection(
            id: id,
            type: type,
            title: raw["title"] as? String,
            subtitle: raw["subtitle"] as? String,
            items: cards(raw["items"], warnings: &warnings, sectionID: id),
            cardStyle: (raw["cardStyle"] as? String).flatMap(CardStyle.init(rawValue:)),
            columns: columnCount,
            body: raw["body"] as? String,
            actionRef: action?["ref"] as? String,
            actionCatalog: action?["catalog"] as? String,
            actionLabel: action?["label"] as? String,
            tags: raw["tags"] as? [String] ?? [],
            feed: raw["feed"] as? String,
            kinds: (raw["kinds"] as? [String] ?? []).compactMap(ContentKind.init(rawValue:)),
            moreTitle: more?["title"] as? String,
            moreCatalog: more?["catalog"] as? String,
            spacerSize: raw["size"] as? String
        )
    }

    private static func cards(_ raw: Any?, warnings: inout [String], sectionID: String) -> [HomeCard] {
        guard let rows = raw as? [[String: Any]] else { return [] }
        return rows.compactMap { row in
            guard let ref = row["ref"] as? String, !ref.isEmpty else {
                warnings.append("bỏ thẻ không ref trong \(sectionID)")
                return nil
            }
            return HomeCard(
                ref: ref,
                kind: (row["kind"] as? String).flatMap(ContentKind.init(rawValue:)),
                title: row["title"] as? String,
                artwork: row["artwork"] as? String
            )
        }
    }

    private static func rawTheme(_ raw: Any?) -> RawTheme? {
        guard let object = raw as? [String: Any] else { return nil }
        return RawTheme(
            accent: object["accent"] as? String,
            background: object["background"] as? String,
            onBackground: object["onBackground"] as? String,
            card: object["card"] as? String,
            radius: (object["radius"] as? String).flatMap(CornerRadiusStyle.init(rawValue:))
        )
    }

    private static func emptyPage(warnings: [String]) -> HomePage {
        HomePage(
            schemaVersion: 1,
            title: nil,
            subtitle: nil,
            theme: nil,
            sections: [],
            itemRefs: [],
            warnings: warnings
        )
    }
}
