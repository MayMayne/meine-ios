import SwiftUI

enum Palette {
    static let pastel = Color(red: 0.557, green: 0.792, blue: 0.902)
    static let accent = Color(red: 0.129, green: 0.620, blue: 0.737)
    static let snow = Color(red: 1, green: 1, blue: 1)
    static let ivory = Color(red: 0.973, green: 0.980, blue: 0.988)

    static func color(hex: String?) -> Color? {
        guard let hex, let parsed = RGB(hex: hex) else { return nil }
        return Color(red: parsed.red, green: parsed.green, blue: parsed.blue)
    }
}

struct RGB: Equatable, Sendable {
    var red: Double
    var green: Double
    var blue: Double

    init?(hex raw: String) {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("#") { text.removeFirst() }
        guard text.count == 6, let value = UInt32(text, radix: 16) else { return nil }
        red = Double((value >> 16) & 0xFF) / 255
        green = Double((value >> 8) & 0xFF) / 255
        blue = Double(value & 0xFF) / 255
    }
}
