import SwiftUI

@main
struct FishigoApp: App {
    @State private var app = AppModel()

    init() {
        Typo.registerBundledFonts()
        Feel.shared.prepare()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .modelContainer(app.container)
                // §6: the archive is dark-ink only; paper lives on cards, not the chrome.
                .preferredColorScheme(.dark)
        }
    }
}
