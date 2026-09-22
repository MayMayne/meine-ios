import Foundation
import CryptoKit

enum SourceLock {
    static func setPassword(_ password: String, sourceID: String) {
        let data = Data(password.utf8)
        try? data.write(to: file(sourceID), options: [.atomic, .completeFileProtection])
    }

    static func password(for sourceID: String) -> String? {
        guard let data = try? Data(contentsOf: file(sourceID)) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func check(_ password: String, sourceID: String) -> Bool {
        password == self.password(for: sourceID)
    }

    static func clear(sourceID: String) {
        try? FileManager.default.removeItem(at: file(sourceID))
    }

    static func hasLock(sourceID: String) -> Bool {
        FileManager.default.fileExists(atPath: file(sourceID).path)
    }

    private static func file(_ sourceID: String) -> URL {
        let digest = SHA256.hash(data: Data(sourceID.utf8)).map { String(format: "%02x", $0) }.joined()
        return LibraryStore.supportDirectory().appendingPathComponent("lock-\(digest).bin")
    }
}

enum BookmarkStore {
    static func save(url: URL, sourceID: String) {
        #if os(iOS)
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil) else {
            return
        }
        try? data.write(to: LibraryStore.supportDirectory().appendingPathComponent("bookmark-\(safe(sourceID)).bin"))
        #endif
    }

    static func resolve(sourceID: String) -> URL? {
        #if os(iOS)
        let url = LibraryStore.supportDirectory().appendingPathComponent("bookmark-\(safe(sourceID)).bin")
        guard let data = try? Data(contentsOf: url) else { return nil }
        var stale = false
        return try? URL(resolvingBookmarkData: data, options: [], relativeTo: nil, bookmarkDataIsStale: &stale)
        #else
        return nil
        #endif
    }

    private static func safe(_ sourceID: String) -> String {
        sourceID.replacingOccurrences(of: "/", with: "_")
    }
}
