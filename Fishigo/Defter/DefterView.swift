import SwiftUI

/// Seyir Defteri: records list, the private map, and stats — three sections
/// under one archive-styled rule bar.
struct DefterView: View {
    enum Bolum: CaseIterable {
        case kayitlar, harita, istatistik

        var title: String {
            switch self {
            case .kayitlar: "KAYITLAR"
            case .harita: "HARİTA"
            case .istatistik: "İSTATİSTİK"
            }
        }
    }

    @State private var bolum: Bolum = .kayitlar

    var body: some View {
        ZStack {
            Ink.murekkepKoyu.ignoresSafeArea()

            VStack(spacing: 0) {
                sectionBar
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                Group {
                    switch bolum {
                    case .kayitlar: LogListView()
                    case .harita: LogMapView()
                    case .istatistik: StatsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var sectionBar: some View {
        HStack(spacing: 0) {
            ForEach(Bolum.allCases, id: \.self) { section in
                Button {
                    guard section != bolum else { return }
                    Feel.shared.tabSwitch()
                    withAnimation(Motion.honoring(Motion.micro)) {
                        bolum = section
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(section.title)
                            .font(Typo.data(12, weight: section == bolum ? .medium : .regular))
                            .kerning(1.5)
                            .foregroundStyle(Ink.kagit.opacity(section == bolum ? 1 : 0.45))
                        Rectangle()
                            .fill(section == bolum ? Ink.kagit : Ink.cizgi.opacity(0.5))
                            .frame(height: section == bolum ? 1.5 : 0.5)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Shared empty state for defter sections.
struct DefterEmptyState: View {
    let caption: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "fish")
                .font(.system(size: 36, weight: .ultraLight))
                .foregroundStyle(Ink.kagit.opacity(0.35))
            Text("Defter henüz boş")
                .font(Typo.display(22))
                .foregroundStyle(Ink.kagit.opacity(0.8))
            Text(caption)
                .font(Typo.data(11))
                .kerning(1)
                .foregroundStyle(Ink.kagit.opacity(0.45))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}
