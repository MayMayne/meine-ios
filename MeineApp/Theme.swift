import SwiftUI

struct Palette {
    var background: Color
    var card: Color
    var accent: Color
    var ink: Color

    static func from(_ settings: AppSettings) -> Palette {
        Palette(
            background: Color(hex: settings.backgroundHex) ?? Color(hex: MeineThemeDefault.background)!,
            card: Color(hex: settings.cardHex) ?? .white,
            accent: Color(hex: settings.accentHex) ?? Color(hex: MeineThemeDefault.accent)!,
            ink: Color(hex: settings.inkHex) ?? Color(hex: MeineThemeDefault.onBackground)!
        )
    }
}

extension Color {
    init?(hex: String) {
        guard let normalized = HexColor.normalize(hex) else { return nil }
        let value = Int(normalized.dropFirst(), radix: 16) ?? 0
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
