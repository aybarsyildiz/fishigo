import SwiftUI

@main
struct FishigoApp: App {
    @State private var app = AppModel()
    @AppStorage("karsilamaGoruldu") private var onboarded = false

    init() {
        Typo.registerBundledFonts()
        Feel.shared.prepare()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if onboarded {
                    RootView()
                } else {
                    OnboardingView {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            onboarded = true
                        }
                    }
                }
            }
            .environment(app)
            .modelContainer(app.container)
            // §6: the archive is dark-ink only; paper lives on cards, not the chrome.
            .preferredColorScheme(.dark)
        }
    }
}
