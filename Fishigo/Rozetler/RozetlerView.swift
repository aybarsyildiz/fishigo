import SwiftUI
import SwiftData

/// The achievements grid — earned badges inked on paper, unearned as dotted
/// engravings, mirroring the deks visual language. Reached from the Balıkdeks
/// header so collection and accomplishment live together.
struct RozetlerView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Query private var records: [CatchRecord]
    @Query private var trips: [EmptyTrip]

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    private var veri: RozetVerisi {
        RozetVerisi(
            records: records,
            emptyTrips: trips,
            species: app.species,
            caughtSpeciesCount: DeksProgress.caughtIds(records).count,
            totalSpecies: app.species.all.count,
            streakWeeks: Sefer.haftalikSeri(outings: records.map(\.date) + trips.map(\.date)))
    }

    var body: some View {
        let earned = Rozetler.earnedIds(veri)
        ZStack {
            Ink.murekkepKoyu.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Text("ROZETLER")
                            .font(Typo.data(11, weight: .medium))
                            .kerning(2)
                            .foregroundStyle(Ink.kagit.opacity(0.5))
                        Spacer()
                        Text("\(earned.count) / \(Rozetler.hepsi.count)")
                            .font(Typo.data(13, weight: .medium))
                            .foregroundStyle(Ink.kagit)
                            .monospacedDigit()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Ink.kagit.opacity(0.6))
                                .padding(8)
                        }
                    }
                    .padding(.top, 16)

                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(Rozetler.hepsi) { rozet in
                            RozetTile(rozet: rozet, earned: earned.contains(rozet.id))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .presentationBackground(Ink.murekkepKoyu)
    }
}

struct RozetTile: View {
    let rozet: Rozet
    let earned: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: rozet.sembol)
                .font(.system(size: 22, weight: earned ? .regular : .ultraLight))
                .foregroundStyle(earned ? Ink.murekkep : Ink.kagit.opacity(0.35))
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(rozet.ad)
                    .font(Typo.data(13, weight: .medium))
                    .foregroundStyle(earned ? Ink.murekkep : Ink.kagit.opacity(0.5))
                Text(rozet.aciklama)
                    .font(Typo.data(9))
                    .foregroundStyle(earned ? Ink.murekkep.opacity(0.6) : Ink.kagit.opacity(0.35))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .background(earned ? Ink.kagit : Ink.murekkep)
        .overlay(
            Rectangle().strokeBorder(
                earned ? Ink.murekkep.opacity(0.5) : Ink.cizgi.opacity(0.7),
                style: earned ? StrokeStyle(lineWidth: 1) : StrokeStyle(lineWidth: 1, dash: [2, 3])))
    }
}

/// Balıkdeks-header module: earned count → opens the grid.
struct RozetlerBar: View {
    @Query private var records: [CatchRecord]
    @Query private var trips: [EmptyTrip]
    @Environment(AppModel.self) private var app

    @State private var show = false

    var body: some View {
        let veri = RozetVerisi(
            records: records, emptyTrips: trips, species: app.species,
            caughtSpeciesCount: DeksProgress.caughtIds(records).count,
            totalSpecies: app.species.all.count,
            streakWeeks: Sefer.haftalikSeri(outings: records.map(\.date) + trips.map(\.date)))
        let earned = Rozetler.earnedIds(veri).count

        Button {
            Feel.shared.buttonTap()
            show = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rosette")
                    .font(.system(size: 15))
                Text("ROZETLER")
                    .font(Typo.data(11, weight: .medium))
                    .kerning(1.5)
                Spacer()
                Text("\(earned) / \(Rozetler.hepsi.count)")
                    .font(Typo.data(12, weight: .medium))
                    .monospacedDigit()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(Ink.kagit.opacity(0.75))
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Ink.murekkep, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Ink.cizgi.opacity(0.6), lineWidth: 0.5))
        }
        .buttonStyle(PressableStyle())
        .sheet(isPresented: $show) { RozetlerView() }
    }
}
