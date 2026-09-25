import Foundation

struct LocalMedia: Identifiable, Equatable, Sendable {
    var id: String
    var kind: ContentKind
    var title: String
    var subtitle: String?
    var relativePath: String
    var coverName: String?
    var extras: [String]
}

enum LocalFolderReader {
    static let coverNames = ["cover.jpg", "cover.png", "cover.webp", "poster.jpg", "poster.png", "folder.jpg"]
    static let lyricExtensions = ["lrc", "srt", "ttml"]
    static let subtitleExtensions = ["srt", "ass", "ssa", "vtt"]
    static let videoExtensions = ["mp4", "mkv", "mov", "m4v", "webm"]
    static let audioExtensions = ["mp3", "flac", "m4a", "aac", "wav", "ogg"]
    static let comicPageExtensions = ["jpg", "jpeg", "png", "webp"]
    static let novelExtensions = ["epub", "txt"]

    static func read(root: URL) -> [LocalMedia] {
        guard let children = try? FileManager.default.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return children.compactMap { url in
            let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            return isDirectory ? readDirectory(url, root: root) : readLooseFile(url, root: root)
        }
        .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    private static func readLooseFile(_ url: URL, root: URL) -> LocalMedia? {
        let ext = url.pathExtension.lowercased()
        let kind: ContentKind
        if novelExtensions.contains(ext) {
            kind = .novel
        } else if ext == "cbz" || ext == "zip" {
            kind = .comic
        } else if videoExtensions.contains(ext) {
            kind = .video
        } else if audioExtensions.contains(ext) {
            kind = .music
        } else {
            return nil
        }
        return media(
            url: url,
            root: root,
            kind: kind,
            title: url.deletingPathExtension().lastPathComponent,
            subtitle: ext.uppercased(),
            coverName: nil,
            extras: []
        )
    }

    private static func readDirectory(_ url: URL, root: URL) -> LocalMedia? {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: url.path)) ?? []
        let kind = inferKind(url: url, names: names)
        guard kind != .unknown else { return nil }
        let lower = Set(names.map { $0.lowercased() })
        let cover = coverNames.first { lower.contains($0) }
        let extras = names.filter { name in
            let ext = (name as NSString).pathExtension.lowercased()
            return lyricExtensions.contains(ext) || subtitleExtensions.contains(ext)
        }
        let chapters = names.filter(isChapterName).count
        let seasons = names.filter(isSeasonName).count
        let subtitle: String?
        if seasons > 0 {
            subtitle = "\(seasons) mùa"
        } else if chapters > 0 {
            subtitle = "\(chapters) chương"
        } else {
            subtitle = nil
        }
        return media(
            url: url,
            root: root,
            kind: kind,
            title: url.lastPathComponent,
            subtitle: subtitle,
            coverName: cover,
            extras: extras
        )
    }

    static func inferKind(url: URL, names: [String]) -> ContentKind {
        if let direct = inferKind(names: names) {
            return direct
        }
        let nested = names.compactMap { name -> ContentKind? in
            let child = url.appendingPathComponent(name)
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: child.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                return nil
            }
            let childNames = (try? FileManager.default.contentsOfDirectory(atPath: child.path)) ?? []
            return inferKind(names: childNames)
        }
        let unique = Set(nested)
        if unique.count == 1, let only = unique.first {
            return only
        }
        return .unknown
    }

    static func inferKind(names: [String]) -> ContentKind? {
        let extensions = names.map { ($0 as NSString).pathExtension.lowercased() }
        if extensions.contains(where: novelExtensions.contains) { return .novel }
        if extensions.contains(where: audioExtensions.contains) { return .music }
        if extensions.contains(where: videoExtensions.contains) { return .video }
        if names.contains(where: isSeasonName) { return .video }
        if names.contains(where: isChapterName) { return .comic }
        if extensions.contains(where: { $0 == "cbz" || $0 == "zip" || comicPageExtensions.contains($0) }) {
            return .comic
        }
        return nil
    }

    static func isChapterName(_ name: String) -> Bool {
        name.range(
            of: #"^(chapter|chap|chương|chuong)[\s._-]*[0-9]+"#,
            options: [.regularExpression, .caseInsensitive]
        ) != nil
    }

    static func isSeasonName(_ name: String) -> Bool {
        name.range(
            of: #"^season[\s._-]*[0-9]+"#,
            options: [.regularExpression, .caseInsensitive]
        ) != nil
    }

    private static func media(
        url: URL,
        root: URL,
        kind: ContentKind,
        title: String,
        subtitle: String?,
        coverName: String?,
        extras: [String]
    ) -> LocalMedia {
        let path = relativePath(url, root: root)
        return LocalMedia(
            id: path,
            kind: kind,
            title: title,
            subtitle: subtitle,
            relativePath: path,
            coverName: coverName,
            extras: extras
        )
    }

    private static func relativePath(_ url: URL, root: URL) -> String {
        let rootPath = root.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        if path.hasPrefix(rootPath + "/") {
            return String(path.dropFirst(rootPath.count + 1))
        }
        return url.lastPathComponent
    }
}
