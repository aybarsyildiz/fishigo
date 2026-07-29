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

/// §2.1-11 quota wall — free 10/month exhausted. Presents the live paywall,
/// and (§2.1-11) never blocks logging: the paywall keeps a "pick manually"
/// escape hatch so the fish still gets into the defter.
struct QuotaWallView: View {
    let model: CatchFlowModel

    @State private var showPaywall = true
    @State private var showList = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "hourglass")
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(Ink.kagit.opacity(0.6))
            Text("Bu ayki 10 tanıma\nhakkın doldu")
                .font(Typo.display(24))
                .foregroundStyle(Ink.kagit)
                .multilineTextAlignment(.center)
            ArchiveButton(title: "Fishigo Pro", systemImage: "rosette") {
                showPaywall = true
            }
            .frame(maxWidth: 240)
            ArchiveButton(title: "Türü listeden seç", systemImage: "list.bullet") {
                showList = true
            }
            .frame(maxWidth: 240)
            Button {
                Feel.shared.buttonTap()
                model.retry()
            } label: {
                Text("VAZGEÇ").font(Typo.data(12)).kerning(1.5)
                    .foregroundStyle(Ink.kagit.opacity(0.5)).padding(8)
            }
            Spacer(); Spacer()
        }
        .padding(24)
        .sheet(isPresented: $showPaywall) {
            PaywallView(kotaBitti: true, onManualPick: { showList = true })
        }
        .sheet(isPresented: $showList) {
            SpeciesListSheet { species in
                showList = false
                model.confirm(species)
            }
        }
    }
}
