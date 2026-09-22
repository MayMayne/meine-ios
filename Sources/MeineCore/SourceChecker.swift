import Foundation

struct SourceIssue: Equatable {
    enum Severity: String { case error, warning }
    var severity: Severity
    var message: String
}

struct SourceCheckReport: Equatable {
    var issues: [SourceIssue]
    var manifest: SourceManifest?
    var home: HomePage?

    var canOpen: Bool {
        manifest != nil && !issues.contains { $0.severity == .error }
    }
}

enum SourceChecker {
    /// Kiểm tra thư mục local. Thiếu manifest thì không mở được. Ảnh gãy chỉ là cảnh báo.
    static func check(root: URL, fileManager: FileManager = .default) -> SourceCheckReport {
        let manifestURL = root.appendingPathComponent("manifest.json")
        guard fileManager.fileExists(atPath: manifestURL.path),
              let data = try? Data(contentsOf: manifestURL) else {
            return SourceCheckReport(
                issues: [SourceIssue(severity: .error, message: "thiếu manifest.json")],
                manifest: nil,
                home: nil
            )
        }
        switch ManifestParser.parse(data) {
        case .failure(let error):
            return SourceCheckReport(
                issues: [SourceIssue(severity: .error, message: error.description)],
                manifest: nil,
                home: nil
            )
        case .success(let manifest):
            return checkParsed(manifest, dataRoot: root, fileManager: fileManager)
        }
    }

    static func checkParsed(
        _ manifest: SourceManifest,
        dataRoot: URL,
        fileManager: FileManager = .default
    ) -> SourceCheckReport {
        var issues = manifest.warnings.map { SourceIssue(severity: .warning, message: $0) }
        let home: HomePage?
        switch manifest.home {
        case .ref(let ref):
            let url = dataRoot.appendingPathComponent(ref)
            if !fileManager.fileExists(atPath: url.path) {
                issues.append(SourceIssue(severity: .error, message: "không thấy \(ref)"))
                home = nil
            } else if let data = try? Data(contentsOf: url) {
                let parsed = HomeParser.parse(data)
                home = parsed.page
                issues.append(contentsOf: parsed.page.warnings.map {
                    SourceIssue(severity: .warning, message: $0)
                })
                issues.append(contentsOf: missingCardTargets(parsed.page, root: dataRoot, fileManager: fileManager))
            } else {
                issues.append(SourceIssue(severity: .error, message: "không đọc được \(ref)"))
                home = nil
            }
        case .inline(let page):
            home = page
        case .tabs(let tabs):
            var pages: [HomePage] = []
            for tab in tabs {
                let url = dataRoot.appendingPathComponent(tab.ref)
                guard fileManager.fileExists(atPath: url.path),
                      let data = try? Data(contentsOf: url) else {
                    issues.append(SourceIssue(severity: .warning, message: "tab \(tab.id) thiếu \(tab.ref)"))
                    continue
                }
                pages.append(HomeParser.parse(data).page)
            }
            home = pages.first
        }
        return SourceCheckReport(issues: issues, manifest: manifest, home: home)
    }

    private static func missingCardTargets(
        _ page: HomePage,
        root: URL,
        fileManager: FileManager
    ) -> [SourceIssue] {
        var issues: [SourceIssue] = []
        let known = Set(page.itemRefs)
        for section in page.sections where section.type != .continue && section.type != .feed {
            for card in section.items where !known.contains(card.ref) {
                issues.append(SourceIssue(
                    severity: .warning,
                    message: "\(card.ref) có trên home nhưng chưa có item đầy đủ trong file này"
                ))
            }
            for card in section.items {
                guard let artwork = card.artwork else { continue }
                if Href.isSafeRelative(artwork),
                   !fileManager.fileExists(atPath: root.appendingPathComponent(artwork).path) {
                    issues.append(SourceIssue(
                        severity: .warning,
                        message: "ảnh thẻ gãy: \(artwork)"
                    ))
                }
                if !Href.isAllowed(artwork) {
                    issues.append(SourceIssue(severity: .warning, message: "artwork không an toàn: \(artwork)"))
                }
            }
        }
        return issues
    }
}
