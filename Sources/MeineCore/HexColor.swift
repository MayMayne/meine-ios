import Foundation

enum HexColor {
    static func normalize(_ raw: String?) -> String? {
        guard var text = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return nil
        }
        if text.hasPrefix("#") { text.removeFirst() }
        guard text.count == 6, text.unicodeScalars.allSatisfy({ isHex($0) }) else { return nil }
        return "#" + text.uppercased()
    }

    static func contrastRatio(_ a: String, _ b: String) -> Double {
        let l1 = relativeLuminance(a)
        let l2 = relativeLuminance(b)
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    static func preferReadableInk(on background: String) -> String {
        contrastRatio("#1B3331", background) >= contrastRatio("#FFFFFF", background)
            ? "#1B3331" : "#FFFFFF"
    }

    private static func isHex(_ scalar: Unicode.Scalar) -> Bool {
        ("0"..."9").contains(Character(scalar))
            || ("a"..."f").contains(Character(scalar))
            || ("A"..."F").contains(Character(scalar))
    }

    private static func relativeLuminance(_ hex: String) -> Double {
        let rgb = channels(hex)
        func lin(_ channel: Double) -> Double {
            let c = channel / 255
            return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * lin(rgb.0) + 0.7152 * lin(rgb.1) + 0.0722 * lin(rgb.2)
    }

    private static func channels(_ hex: String) -> (Double, Double, Double) {
        let cleaned = normalize(hex) ?? "#000000"
        let value = Int(cleaned.dropFirst(), radix: 16) ?? 0
        return (
            Double((value >> 16) & 0xFF),
            Double((value >> 8) & 0xFF),
            Double(value & 0xFF)
        )
    }
}

enum Href {
    static func isAbsoluteHTTP(_ value: String) -> Bool {
        let lower = value.lowercased()
        return lower.hasPrefix("https://") || lower.hasPrefix("http://")
    }

    /// Path tương đối trong gốc nguồn. Từ chối `..`, scheme lạ và đường tuyệt đối.
    static func isSafeRelative(_ value: String) -> Bool {
        let text = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty || text.hasPrefix("/") || text.contains("\\") { return false }
        if text.contains("://") { return false }
        let parts = text.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        if parts.contains("..") || parts.contains(".") { return false }
        return !parts.contains(where: \.isEmpty)
    }

    static func isAllowed(_ value: String) -> Bool {
        isAbsoluteHTTP(value) || isSafeRelative(value)
    }
}

enum SourceID {
    static let pattern = "^[a-z0-9._-]{3,80}$"

    static func isValid(_ id: String) -> Bool {
        id.range(of: pattern, options: .regularExpression) != nil
    }
}

enum SemVer {
    static func isValid(_ value: String) -> Bool {
        value.range(of: "^\\d+\\.\\d+\\.\\d+$", options: .regularExpression) != nil
    }
}
