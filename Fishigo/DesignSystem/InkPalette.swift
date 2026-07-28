import SwiftUI

/// §6 design tokens — "Naturalist Specimen Archive".
/// Flat inks + paper only. No neon, no gradients, no glass, no iOS-blue.
enum Ink {
    /// Marine ink — dark surfaces, engraving fill.
    static let murekkep = Color(hex: 0x16303D)
    /// App background.
    static let murekkepKoyu = Color(hex: 0x0F222C)
    /// Chart paper — cards, sheets.
    static let kagit = Color(hex: 0xEDE5D1)
    /// Printed hairlines.
    static let cizgi = Color(hex: 0x28414E)
    /// Stamp red — THE accent. One per screen, maximum.
    static let muhur = Color(hex: 0xC2402F)
    /// Brass ink — rarity / record accents.
    static let pirinc = Color(hex: 0x8F6F26)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255)
    }
}
