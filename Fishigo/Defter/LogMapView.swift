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
            Map(initialPosition: .automatic) {
                ForEach(located) { record in
                    if let coordinate = record.coordinate {
                        Annotation(annotationTitle(record), coordinate: coordinate) {
                            SpotMarker(isFirst: record.isFirstOfSpecies)
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

    private func annotationTitle(_ record: CatchRecord) -> String {
        app.species.species(id: record.speciesId)?.displayName(lengthCm: record.lengthCm) ?? ""
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
