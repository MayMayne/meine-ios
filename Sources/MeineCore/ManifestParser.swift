import Foundation

enum ManifestParser {
    static func parse(_ data: Data) -> Result<SourceManifest, ManifestParseError> {
        guard let json = try? JSONSerialization.jsonObject(with: data) else {
            return .failure(.notJSON)
        }
        guard let object = json as? [String: Any] else { return .failure(.notObject) }
        return parseObject(object)
    }

    static func parseObject(_ object: [String: Any]) -> Result<SourceManifest, ManifestParseError> {
        guard let schema = object["schemaVersion"] as? Int else {
            return .failure(.missing("schemaVersion"))
        }
        guard schema == 1 else { return .failure(.badVersion) }
        guard let id = object["id"] as? String, SourceID.isValid(id) else {
            return .failure(.badID)
        }
        guard let name = object["name"] as? String, !name.isEmpty, name.count <= 60 else {
            return .failure(.missing("name"))
        }
        guard let version = object["version"] as? String, SemVer.isValid(version) else {
            return .failure(.missing("version"))
        }
        let known = knownKinds(object["kinds"])
        if known.isEmpty { return .failure(.noKinds) }

        guard let homeObject = object["home"] as? [String: Any] else {
            return .failure(.homeMissing)
        }
        let home: HomePointer
        switch parseHomePointer(homeObject) {
        case .success(let pointer):
            home = pointer
        case .failure(let error):
            return .failure(error)
        }

        guard let endpointsObject = object["endpoints"] as? [String: Any],
              let catalog = endpointsObject["catalog"] as? String,
              Href.isAllowed(catalog) else {
            return .failure(.catalogMissing)
        }

        var warnings: [String] = []
        let dropped = droppedKindNames(object["kinds"])
        if !dropped.isEmpty {
            warnings.append("bỏ kind lạ: \(dropped.joined(separator: ", "))")
        }

        let manifest = SourceManifest(
            schemaVersion: schema,
            id: id,
            name: name,
            version: version,
            summary: object["summary"] as? String,
            defaultLocale: (object["defaultLocale"] as? String) ?? "vi",
            kinds: known,
            home: home,
            endpoints: SourceEndpoints(
                catalog: catalog,
                search: endpointsObject["search"] as? String,
                resolve: endpointsObject["resolve"] as? String,
                item: endpointsObject["item"] as? String,
                mediaTemplate: endpointsObject["mediaTemplate"] as? String
            ),
            theme: SourceTheme.resolved(from: rawTheme(object["theme"])),
            capabilities: capabilities(object["capabilities"]),
            auth: auth(object["auth"]),
            cacheTtl: cacheTtl(object["cacheTtl"]),
            minAppVersion: object["minAppVersion"] as? String,
            warnings: warnings
        )
        return .success(manifest)
    }

    static func parseHomePointer(_ object: [String: Any]) -> Result<HomePointer, ManifestParseError> {
        let hasRef = object["ref"] is String
        let hasInline = object["inline"] is [String: Any]
        let hasTabs = object["tabs"] is [Any]
        if [hasRef, hasInline, hasTabs].filter({ $0 }).count != 1 {
            return .failure(.homeMissing)
        }
        if let ref = object["ref"] as? String {
            guard Href.isSafeRelative(ref) else { return .failure(.homeMissing) }
            return .success(.ref(ref))
        }
        if let inline = object["inline"] as? [String: Any] {
            return .success(.inline(HomeParser.parseObject(inline).page))
        }
        let tabsRaw = object["tabs"] as? [[String: Any]] ?? []
        if tabsRaw.count > 6 { return .failure(.tooManyTabs) }
        let tabs: [SourceHomeTab] = tabsRaw.compactMap { tab in
            guard let id = tab["id"] as? String,
                  let title = tab["title"] as? String,
                  let ref = tab["ref"] as? String,
                  Href.isSafeRelative(ref) else { return nil }
            return SourceHomeTab(id: id, title: title, ref: ref)
        }
        if tabs.isEmpty { return .failure(.homeMissing) }
        return .success(.tabs(tabs))
    }

    private static func knownKinds(_ raw: Any?) -> [ContentKind] {
        guard let names = raw as? [String] else { return [] }
        var seen = Set<String>()
        return names.compactMap { name in
            guard seen.insert(name).inserted else { return nil }
            return ContentKind(rawValue: name)
        }
    }

    private static func droppedKindNames(_ raw: Any?) -> [String] {
        guard let names = raw as? [String] else { return [] }
        return names.filter { ContentKind(rawValue: $0) == nil }
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

    private static func capabilities(_ raw: Any?) -> [String: CapabilityValue] {
        guard let object = raw as? [String: Any] else { return [:] }
        var parsed: [String: CapabilityValue] = [:]
        for (key, value) in object {
            guard let text = value as? String, let flag = CapabilityValue(rawValue: text) else { continue }
            parsed[key] = flag
        }
        return parsed
    }

    private static func auth(_ raw: Any?) -> SourceAuth {
        guard let object = raw as? [String: Any] else {
            return SourceAuth(mode: .none, scope: .app, hint: nil, keyId: nil)
        }
        let mode = (object["mode"] as? String).flatMap(AuthMode.init(rawValue:)) ?? .none
        let scope = (object["scope"] as? String).flatMap(AuthScope.init(rawValue:)) ?? .app
        return SourceAuth(
            mode: mode,
            scope: scope,
            hint: object["hint"] as? String,
            keyId: object["keyId"] as? String
        )
    }

    private static func cacheTtl(_ raw: Any?) -> Int {
        if let number = raw as? Int, number >= 0 { return number }
        if let number = raw as? Double, number >= 0 { return Int(number) }
        return 3600
    }
}
