import SwiftUI

struct RootView: View {
    enum Tab: Hashable {
        case deks, yakala, defter
    }

    @State private var selection: Tab = .yakala

    var body: some View {
        TabView(selection: $selection) {
            PlaceholderScreen(
                title: "Balıkdeks",
                latin: "Collectio Piscium Turcicae",
                note: "M3: 70 tür, noktalı gravür siluetler")
                .tabItem { Label("Balıkdeks", systemImage: "square.grid.3x3") }
                .tag(Tab.deks)

            CatchFlowView()
                .tabItem { Label("Yakala", systemImage: "camera") }
                .tag(Tab.yakala)

            PlaceholderScreen(
                title: "Seyir Defteri",
                latin: "Diarium Nauticum",
                note: "M2: kayıtlar, özel harita, istatistik")
                .tabItem { Label("Defter", systemImage: "book.closed") }
                .tag(Tab.defter)
        }
        .tint(Ink.kagit)
        .onChange(of: selection) {
            Feel.shared.tabSwitch()
        }
    }
}

/// Milestone placeholder styled in the archive language: double-rule specimen
/// frame, Fraunces display, Plex Mono data line. Replaced screen by screen.
struct PlaceholderScreen: View {
    let title: String
    let latin: String
    let note: String

    var body: some View {
        ZStack {
            Ink.murekkepKoyu.ignoresSafeArea()

            VStack(spacing: 14) {
                Text(title)
                    .font(Typo.display(34))
                    .foregroundStyle(Ink.kagit)
                Text(latin)
                    .font(Typo.latin(15))
                    .foregroundStyle(Ink.kagit.opacity(0.65))
                Rectangle()
                    .fill(Ink.cizgi)
                    .frame(width: 120, height: 1)
                Text(note)
                    .font(Typo.data(13))
                    .foregroundStyle(Ink.kagit.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .padding(36)
            .background(Ink.murekkep)
            .overlay(DoubleRuleFrame())
            .padding(24)
        }
    }
}

/// §6: double-rule specimen frame — a heavier outer rule with a thin inner rule.
struct DoubleRuleFrame: View {
    var color: Color = Ink.cizgi

    var body: some View {
        ZStack {
            Rectangle().strokeBorder(color, lineWidth: 1.5)
            Rectangle().strokeBorder(color.opacity(0.7), lineWidth: 0.5).padding(5)
        }
    }
}

#Preview {
    RootView()
        .preferredColorScheme(.dark)
}
