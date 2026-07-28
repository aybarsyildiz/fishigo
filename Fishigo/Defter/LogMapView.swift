import SwiftUI
import SwiftData
import MapKit

/// §9: the private map. Own catches only, never shared, never exported.
/// There is no mechanism to share a spot — "Noktan sende kalır."
struct LogMapView: View {
    @Environment(AppModel.self) private var app
    @Query(sort: \CatchRecord.date, order: .reverse) private var records: [CatchRecord]

    private var located: [CatchRecord] {
        records.filter { $0.coordinate != nil }
    }

    var body: some View {
        if records.isEmpty {
            DefterEmptyState(caption: "YAKALADIĞIN NOKTALAR SADECE\nSENİN HARİTANDA GÖRÜNÜR")
        } else if located.isEmpty {
            DefterEmptyState(caption: "KONUMLU KAYIT YOK —\nKONUM İZNİ İLE NOKTALAR BURAYA İŞLENİR")
        } else {
            // Private heat rendering: stacked translucent circles per catch —
            // overlaps accumulate, so a productive spot literally glows hotter.
            // (§9: this heat view exists ONLY here, on the owner's own map.
            // The banned thing is PUBLIC/shared heatmaps — never this.)
            Map(initialPosition: .automatic) {
                ForEach(located) { record in
                    if let coordinate = record.coordinate {
                        MapCircle(center: coordinate, radius: 600)
                            .foregroundStyle(Ink.muhur.opacity(0.07))
                        MapCircle(center: coordinate, radius: 280)
                            .foregroundStyle(Ink.muhur.opacity(0.13))
                        MapCircle(center: coordinate, radius: 100)
                            .foregroundStyle(Ink.muhur.opacity(0.22))
                        Annotation(coordinate: coordinate) {
                            Circle()
                                .fill(Ink.kagit)
                                .frame(width: 4, height: 4)
                        } label: {
                            EmptyView()
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
            .overlay(alignment: .bottom) {
                Text("NOKTAN SENDE KALIR — BU HARİTA SADECE SENİN")
                    .font(Typo.data(9))
                    .kerning(1)
                    .foregroundStyle(Ink.kagit.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Ink.murekkepKoyu.opacity(0.85), in: Capsule())
                    .padding(.bottom, 12)
            }
        }
    }

}

/// Ink dot with a paper ring — reads as a chart sounding, not a pin.
struct SpotMarker: View {
    let isFirst: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Ink.murekkepKoyu)
                .frame(width: 22, height: 22)
            Circle()
                .strokeBorder(isFirst ? Ink.muhur : Ink.kagit, lineWidth: 1.5)
                .frame(width: 22, height: 22)
            Image(systemName: "fish")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Ink.kagit)
        }
    }
}
