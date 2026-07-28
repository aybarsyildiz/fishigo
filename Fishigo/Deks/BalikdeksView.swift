import SwiftUI
import SwiftData

/// The collection (§2.1-5): every species as a specimen plate — dotted
/// engraving until caught, inked on paper after. Tiles flip in as a cascade
/// with a selection tick per card (§7).
struct BalikdeksView: View {
    @Environment(AppModel.self) private var app
    @Query private var records: [CatchRecord]

    @State private var revealed = false
    @State private var selected: Species?

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    private var caught: Set<String> { DeksProgress.caughtIds(records) }

    var body: some View {
        ZStack {
            Ink.murekkepKoyu.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    header
                        .padding(.top, 12)

                    RozetlerBar()

                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(Array(app.species.all.enumerated()), id: \.element.id) { index, species in
                            DeksTile(species: species, caught: caught.contains(species.id))
                                .rotation3DEffect(
                                    .degrees(revealed || Motion.reduceMotion ? 0 : 90),
                                    axis: (x: 0, y: 1, z: 0))
                                .opacity(revealed ? 1 : 0)
                                .animation(
                                    Motion.honoring(Motion.micro).delay(Double(min(index, 24)) * 0.03),
                                    value: revealed)
                                .onTapGesture {
                                    Feel.shared.cardLift()
                                    selected = species
                                }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .task {
            guard !revealed else { return }
            revealed = true
            // §7: cascade ticks ride the stagger for the first screenful.
            for _ in 0..<12 {
                try? await Task.sleep(for: .milliseconds(30))
                Feel.shared.deksCascadeTick()
            }
        }
        .sheet(item: $selected) { species in
            DeksDetailSheet(species: species)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("BALIKDEKS")
                .font(Typo.data(12, weight: .medium))
                .kerning(3)
                .foregroundStyle(Ink.kagit.opacity(0.5))
            Text("\(caught.count) / \(app.species.all.count)")
                .font(Typo.display(34))
                .foregroundStyle(Ink.kagit)
                .monospacedDigit()
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Ink.cizgi.opacity(0.6))
                    Rectangle()
                        .fill(Ink.kagit)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 2)
            .frame(maxWidth: 180)
        }
    }

    private var progress: CGFloat {
        let total = app.species.all.count
        guard total > 0 else { return 0 }
        return CGFloat(caught.count) / CGFloat(total)
    }
}

/// One specimen plate. Uncaught: dotted engraving on ink. Caught: solid ink
/// on paper. Brass frame from epik upward, once caught (§8).
struct DeksTile: View {
    let species: Species
    let caught: Bool

    var body: some View {
        VStack(spacing: 8) {
            SilhouetteView(tip: species.siluetTipi, caught: caught)
                .frame(height: 40)
                .padding(.horizontal, 6)
            Text(species.ad.localizedUppercase)
                .font(Typo.data(8, weight: caught ? .medium : .regular))
                .kerning(0.5)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(caught ? Ink.murekkep : Ink.kagit.opacity(0.4))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .background(caught ? Ink.kagit : Ink.murekkep)
        .overlay(
            Rectangle().strokeBorder(
                caught
                    ? (species.nadirlik.hasBrassAccent ? Ink.pirinc : Ink.murekkep.opacity(0.55))
                    : Ink.cizgi.opacity(0.7),
                lineWidth: caught && species.nadirlik.hasBrassAccent ? 1.5 : 1))
        .contentShape(Rectangle())
    }
}
