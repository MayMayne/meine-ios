import Foundation

struct LyricLine: Equatable, Identifiable {
    var id: Int
    var start: TimeInterval
    var end: TimeInterval?
    var text: String
    var words: [LyricWord]
}

struct LyricWord: Equatable {
    var start: TimeInterval
    var text: String
}

enum LyricCueParser {
    static func parse(text: String, format: String) -> [LyricLine] {
        switch format.lowercased() {
        case "srt", "vtt":
            return parseSRT(text)
        case "ttml":
            return parseTTML(text)
        case "plain", "txt":
            return [LyricLine(id: 0, start: 0, end: nil, text: text, words: [])]
        default:
            return parseLRC(text)
        }
    }

    static func parseLRC(_ text: String) -> [LyricLine] {
        var stamped: [(TimeInterval, String, [LyricWord])] = []
        for raw in text.split(whereSeparator: \.isNewline) {
            let line = String(raw).trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("[ar:") || line.hasPrefix("[ti:") || line.hasPrefix("[al:") || line.hasPrefix("[offset:") {
                continue
            }
            let times = stampTimes(in: line)
            if times.isEmpty { continue }
            let body = line.replacingOccurrences(of: "\\[\\d{1,2}:\\d{2}(?:[\\.:]\\d{1,3})?\\]", with: "", options: .regularExpression)
            let words = enhancedWords(body)
            let plain = words.isEmpty ? body.trimmingCharacters(in: .whitespaces) : words.map(\.text).joined()
            if plain.isEmpty { continue }
            for time in times {
                stamped.append((time, plain, words))
            }
        }
        stamped.sort { $0.0 < $1.0 }
        return stamped.enumerated().map { index, row in
            let end = index + 1 < stamped.count ? stamped[index + 1].0 : nil
            return LyricLine(id: index, start: row.0, end: end, text: row.1, words: row.2)
        }
    }

    static func parseSRT(_ text: String) -> [LyricLine] {
        let chunks = text.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n\n")
        var lines: [LyricLine] = []
        for chunk in chunks {
            let rows = chunk.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            guard let timeRow = rows.first(where: { $0.contains("-->") }) else { continue }
            let parts = timeRow.components(separatedBy: "-->")
            guard parts.count == 2 else { continue }
            let start = clock(parts[0])
            let end = clock(parts[1])
            let body = rows.drop { !$0.contains("-->") }.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if body.isEmpty { continue }
            lines.append(LyricLine(id: lines.count, start: start, end: end, text: body, words: []))
        }
        return lines
    }

    static func parseTTML(_ text: String) -> [LyricLine] {
        // Enough for <p begin="00:00:01.000" end="...">line</p>. Nested word spans stay plain text.
        var lines: [LyricLine] = []
        let pattern = #"begin="([^"]+)"[^>]*>([^<]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return lines }
        let ns = text as NSString
        for match in regex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            let begin = ns.substring(with: match.range(at: 1))
            let body = ns.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
            if body.isEmpty { continue }
            lines.append(LyricLine(id: lines.count, start: clock(begin), end: nil, text: body, words: []))
        }
        return lines
    }

    static func activeIndex(lines: [LyricLine], at time: TimeInterval) -> Int? {
        lines.lastIndex { $0.start <= time + 0.05 }
    }

    private static func stampTimes(in line: String) -> [TimeInterval] {
        guard let regex = try? NSRegularExpression(pattern: #"\[(\d{1,2}):(\d{2})(?:[\.:](\d{1,3}))?\]"#) else {
            return []
        }
        let ns = line as NSString
        return regex.matches(in: line, range: NSRange(location: 0, length: ns.length)).compactMap { match in
            let minute = Double(ns.substring(with: match.range(at: 1))) ?? 0
            let second = Double(ns.substring(with: match.range(at: 2))) ?? 0
            var fraction = 0.0
            if match.range(at: 3).location != NSNotFound {
                let raw = ns.substring(with: match.range(at: 3))
                fraction = (Double(raw) ?? 0) / pow(10, Double(raw.count))
            }
            return minute * 60 + second + fraction
        }
    }

    private static func enhancedWords(_ body: String) -> [LyricWord] {
        guard body.contains("<"),
              let regex = try? NSRegularExpression(pattern: #"([^<]*)<(\d{1,2}):(\d{2})(?:[\.:](\d{1,3}))?>"#) else {
            return []
        }
        let ns = body as NSString
        let matches = regex.matches(in: body, range: NSRange(location: 0, length: ns.length))
        if matches.isEmpty { return [] }
        return matches.compactMap { match in
            let word = ns.substring(with: match.range(at: 1))
            if word.trimmingCharacters(in: .whitespaces).isEmpty { return nil }
            let minute = Double(ns.substring(with: match.range(at: 2))) ?? 0
            let second = Double(ns.substring(with: match.range(at: 3))) ?? 0
            return LyricWord(start: minute * 60 + second, text: word)
        }
    }

    static func clock(_ raw: String) -> TimeInterval {
        let cleaned = raw.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        let parts = cleaned.split(separator: ":").map(String.init)
        if parts.count == 3 {
            let hour = Double(parts[0]) ?? 0
            let minute = Double(parts[1]) ?? 0
            let second = Double(parts[2]) ?? 0
            return hour * 3600 + minute * 60 + second
        }
        if parts.count == 2 {
            let minute = Double(parts[0]) ?? 0
            let second = Double(parts[1]) ?? 0
            return minute * 60 + second
        }
        return Double(cleaned) ?? 0
    }
}
