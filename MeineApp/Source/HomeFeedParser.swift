import Foundation

enum HomeFeedParser {
    static func parse(_ data: Data) throws -> HomeFeed {
        try JSONDecoder().decode(HomeFeed.self, from: data)
    }

    static func parse(json: String) throws -> HomeFeed {
        guard let data = json.data(using: .utf8) else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }
        return try parse(data)
    }
}
