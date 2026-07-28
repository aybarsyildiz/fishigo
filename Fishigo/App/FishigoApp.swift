import SwiftUI

@main
struct FishigoApp: App {
    init() {
        Typo.registerBundledFonts()
        Feel.shared.prepare()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                // §6: the archive is dark-ink only; paper lives on cards, not the chrome.
                .preferredColorScheme(.dark)
        }
    }
}
