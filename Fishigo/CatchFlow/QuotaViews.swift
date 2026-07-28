import SwiftUI

/// Recognition failed (network/service). Retrying is one tap; and because the
/// app is local-first, the catch can ALWAYS be logged by picking the species
/// manually — a dead spot at the shore never blocks the defter.
struct NetworkErrorView: View {
    let model: CatchFlowModel

    @State private var showList = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "wifi.slash")
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(Ink.kagit.opacity(0.6))
            Text("Bağlantı\nkurulamadı")
                .font(Typo.display(26))
                .foregroundStyle(Ink.kagit)
                .multilineTextAlignment(.center)
            Text("KIYIDA ÇEKMİYOR OLABİLİR — KAYIT YİNE DE SENDE")
                .font(Typo.data(10))
                .kerning(1.5)
                .foregroundStyle(Ink.kagit.opacity(0.5))
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                ArchiveButton(title: "Tekrar dene", systemImage: "arrow.counterclockwise") {
                    model.tekrarTani()
                }
                ArchiveButton(title: "Türü listeden seç", systemImage: "list.bullet") {
                    showList = true
                }
            }
            .frame(maxWidth: 250)
            .padding(.top, 6)

            Button {
                Feel.shared.buttonTap()
                model.retry()
            } label: {
                Text("VAZGEÇ")
                    .font(Typo.data(12))
                    .kerning(1.5)
                    .foregroundStyle(Ink.kagit.opacity(0.5))
                    .padding(8)
            }

            Spacer()
            Spacer()
        }
        .padding(24)
        .sheet(isPresented: $showList) {
            SpeciesListSheet { species in
                showList = false
                model.confirm(species)
            }
        }
    }
}

/// §2.1-11: paywall STUB only — screen + product-id placeholders, no live
/// purchase flow in v1. Quota running out never blocks logging the fish.
struct PaywallStubView: View {
    let model: CatchFlowModel

    @State private var showList = false

    // TODO(v1.x): StoreKit products — fishigo.pro.aylik / fishigo.pro.yillik
    private let features = [
        "SINIRSIZ TÜR TANIMA",
        "GELİŞMİŞ KOŞUL PUANI",
        "ARŞİV DIŞA AKTARIMI",
    ]

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            VStack(spacing: 14) {
                Text("BU AYKİ 10 TANIMA HAKKIN DOLDU")
                    .font(Typo.data(10))
                    .kerning(1.5)
                    .foregroundStyle(Ink.kagit.opacity(0.55))
                Text("Fishigo Pro")
                    .font(Typo.display(32))
                    .foregroundStyle(Ink.kagit)
                Text("YAKINDA")
                    .font(Typo.data(10, weight: .semibold))
                    .kerning(3)
                    .foregroundStyle(Ink.pirinc)

                Rectangle().fill(Ink.cizgi).frame(width: 110, height: 1)

                VStack(spacing: 8) {
                    ForEach(features, id: \.self) { feature in
                        Text(feature)
                            .font(Typo.data(11))
                            .kerning(1)
                            .foregroundStyle(Ink.kagit.opacity(0.7))
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .background(Ink.murekkep)
            .overlay(DoubleRuleFrame(color: Ink.pirinc))

            Text("Balığını yine de kaydedebilirsin —\ntanıma hakkı sadece otomatik teşhis için.")
                .font(Typo.data(11))
                .foregroundStyle(Ink.kagit.opacity(0.55))
                .multilineTextAlignment(.center)

            ArchiveButton(title: "Türü listeden seç", systemImage: "list.bullet") {
                showList = true
            }
            .frame(maxWidth: 250)

            Button {
                Feel.shared.buttonTap()
                model.retry()
            } label: {
                Text("VAZGEÇ")
                    .font(Typo.data(12))
                    .kerning(1.5)
                    .foregroundStyle(Ink.kagit.opacity(0.5))
                    .padding(8)
            }

            Spacer()
        }
        .padding(24)
        .sheet(isPresented: $showList) {
            SpeciesListSheet { species in
                showList = false
                model.confirm(species)
            }
        }
    }
}
