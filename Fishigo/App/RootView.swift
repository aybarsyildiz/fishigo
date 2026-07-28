import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        @Bindable var app = app
        TabView(selection: $app.tab) {
            BalikdeksView()
                .tabItem { Label("Balıkdeks", systemImage: "square.grid.3x3") }
                .tag(AppTab.deks)

            CatchFlowView()
                .tabItem { Label("Yakala", systemImage: "camera") }
                .tag(AppTab.yakala)

            DefterView()
                .tabItem { Label("Defter", systemImage: "book.closed") }
                .tag(AppTab.defter)
        }
        .tint(Ink.kagit)
        .onChange(of: app.tab) {
            Feel.shared.tabSwitch()
        }
    }
}

#Preview {
    RootView()
        .environment(AppModel())
        .preferredColorScheme(.dark)
}
