import SwiftUI
import CoreText
import UIKit

/// §6 typography — Fraunces (900 display, italic Latin names) + IBM Plex Mono
/// (data, labels, tables). Fonts are registered at runtime from the bundle so
/// no Info.plist UIAppFonts entry is needed; every accessor degrades to the
/// closest system design until the real files ship / are verified.
/// TODO(M1): verify Turkish glyphs (ı İ ş Ş ğ Ğ ç Ç ö Ö ü Ü) on device.
enum Typo {
    /// Registers every bundled .ttf with the process. Call once at app start.
    static func registerBundledFonts() {
        var urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        urls += Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") ?? []
        guard !urls.isEmpty else { return }
        CTFontManagerRegisterFontURLs(urls as CFArray, .process, true, nil)
    }

    /// Species names, display headers — Fraunces 900.
    static func display(_ size: CGFloat) -> Font {
        if let font = firstAvailable(["Fraunces-Black", "Fraunces72pt-Black", "Fraunces"], size: size) {
            return font.weight(.black)
        }
        return .system(size: size, weight: .black, design: .serif)
    }

    /// Latin species names — Fraunces italic.
    static func latin(_ size: CGFloat) -> Font {
        let base = firstAvailable(["Fraunces-Italic", "Fraunces-BlackItalic", "FrauncesItalic"], size: size)
            ?? .system(size: size, design: .serif)
        return base.italic()
    }

    /// Data, labels, tables — IBM Plex Mono.
    static func data(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if let font = firstAvailable(["IBMPlexMono", "IBMPlexMono-Regular"], size: size) {
            return font.weight(weight)
        }
        return .system(size: size, weight: weight, design: .monospaced)
    }

    private static func firstAvailable(_ names: [String], size: CGFloat) -> Font? {
        for name in names where UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }
        return nil
    }
}
