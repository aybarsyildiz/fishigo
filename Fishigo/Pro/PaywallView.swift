import SwiftUI
import StoreKit

/// Fishigo Pro paywall — built to pass App Review Guideline 3.1.2:
/// price + billing period per plan, a plain feature list, the auto-renew
/// disclosure text, a Restore button, and functional Terms + Privacy links.
struct PaywallView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    /// When shown because the free quota ran out, we say so and keep the
    /// "log it anyway" escape hatch (§2.1-11: quota never blocks logging).
    var kotaBitti: Bool = false
    var onManualPick: (() -> Void)?

    @State private var seciliYillik = true
    @State private var calisiyor = false
    @State private var hata: String?
    @State private var demoTaps = 0
    @State private var showDemoCode = false
    @State private var demoCode = ""
    /// Tracks whether a product-load attempt has finished, so we can tell
    /// "loading" apart from "loaded but empty" (config/ASC not available).
    @State private var yuklemeDenendi = false

    private var pro: ProStore { app.pro }

    private let features = [
        ("infinity", "Sınırsız tür tanıma", "Aylık 10 sınırı olmadan"),
        ("square.grid.2x2", "Kova modu", "Tek fotoğrafla tüm avı kaydet"),
        ("chart.xyaxis.line", "Koşullar & Bugün ne tutulur", "Bölge + sezon önerileri"),
        ("bell", "Günlük koşul bildirimi", "Her sabah tek hatırlatma"),
        ("doc.text.image", "Sezon kartı & gelişmiş istatistik", "Aylık özet paylaşımı"),
    ]

    var body: some View {
        ZStack {
            Ink.murekkepKoyu.ignoresSafeArea()
            ChartFragment().ignoresSafeArea().opacity(0.4)

            ScrollView {
                VStack(spacing: 16) {
                    baslik
                    ozellikler
                    planlar
                    satinAlButonu
                    // §3.1.2 auto-renew disclosure — required, verbatim intent.
                    Text("Ödeme, satın alma onayında Apple Kimliğine işlenir. Abonelik, dönem bitiminden en az 24 saat önce kapatılmazsa otomatik yenilenir; yenileme ücreti dönemin bitiminden önceki 24 saat içinde alınır. Abonelikleri satın aldıktan sonra Ayarlar'dan yönetebilir veya iptal edebilirsin.")
                        .font(Typo.data(9))
                        .foregroundStyle(Ink.kagit.opacity(0.45))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                    altBaglantilar

                    if kotaBitti, let onManualPick {
                        Button {
                            Feel.shared.buttonTap()
                            dismiss()
                            onManualPick()
                        } label: {
                            Text("YİNE DE TÜRÜ LİSTEDEN SEÇ")
                                .font(Typo.data(11)).kerning(1.5)
                                .foregroundStyle(Ink.kagit.opacity(0.6))
                                .padding(8)
                        }
                    }
                }
                .padding(20)
            }

            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Ink.kagit.opacity(0.6))
                            .padding(14)
                    }
                }
                Spacer()
            }
        }
        .alert("Bir sorun oldu", isPresented: .constant(hata != nil)) {
            Button("Tamam") { hata = nil }
        } message: { Text(hata ?? "") }
        .alert("Demo kodu", isPresented: $showDemoCode) {
            TextField("Kod", text: $demoCode)
            Button("Aç") { Task { await denemeDemo() } }
            Button("Vazgeç", role: .cancel) { }
        } message: { Text("İnceleme demo erişimi.") }
        .task {
            // Re-attempt loading when the paywall opens (products load at launch,
            // but a transient miss or a just-selected StoreKit config resolves here).
            if pro.products.isEmpty { await pro.load() }
            yuklemeDenendi = true
        }
    }

    private var baslik: some View {
        VStack(spacing: 8) {
            // Hidden reviewer-access gesture (playbook §6): 7 taps on the seal.
            Image(systemName: "rosette")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Ink.muhur)
                .padding(.top, 30)
                .onTapGesture {
                    demoTaps += 1
                    if demoTaps >= 7 { demoTaps = 0; showDemoCode = true }
                }
            Text("Fishigo Pro")
                .font(Typo.display(34))
                .foregroundStyle(Ink.kagit)
            Text(kotaBitti ? "BU AYKİ 10 TANIMA HAKKIN DOLDU" : "ARŞİVİNİ SINIRSIZ BÜYÜT")
                .font(Typo.data(10, weight: .medium)).kerning(2)
                .foregroundStyle(Ink.kagit.opacity(0.55))
        }
    }

    private var ozellikler: some View {
        VStack(spacing: 0) {
            ForEach(Array(features.enumerated()), id: \.offset) { index, f in
                HStack(spacing: 14) {
                    Image(systemName: f.0)
                        .font(.system(size: 17))
                        .foregroundStyle(Ink.pirinc)
                        .frame(width: 26)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(f.1).font(Typo.data(14, weight: .medium)).foregroundStyle(Ink.kagit)
                        Text(f.2).font(Typo.data(10)).foregroundStyle(Ink.kagit.opacity(0.5))
                    }
                    Spacer()
                }
                .padding(.vertical, 11).padding(.horizontal, 14)
                if index < features.count - 1 {
                    Rectangle().fill(Ink.cizgi.opacity(0.4)).frame(height: 0.5)
                }
            }
        }
        .background(Ink.murekkep)
        .overlay(DoubleRuleFrame())
    }

    private var planlar: some View {
        VStack(spacing: 10) {
            if let annual = pro.annual {
                PlanRow(product: annual, period: "yıl", secili: seciliYillik, rozet: "2 AY BEDAVA") {
                    seciliYillik = true; Feel.shared.buttonTap()
                }
            }
            if let monthly = pro.monthly {
                PlanRow(product: monthly, period: "ay", secili: !seciliYillik, rozet: nil) {
                    seciliYillik = false; Feel.shared.buttonTap()
                }
            }
            if pro.products.isEmpty {
                VStack(spacing: 10) {
                    Text(yuklemeDenendi ? "PLANLARA ŞU AN ULAŞILAMIYOR" : "PLANLAR YÜKLENİYOR…")
                        .font(Typo.data(10)).kerning(1)
                        .foregroundStyle(Ink.kagit.opacity(0.4))
                    if yuklemeDenendi {
                        Button {
                            Feel.shared.buttonTap()
                            Task { await pro.load() }
                        } label: {
                            Text("TEKRAR DENE")
                                .font(Typo.data(11)).kerning(1.5)
                                .foregroundStyle(Ink.kagit.opacity(0.7))
                                .padding(8)
                        }
                    }
                }
                .padding(.vertical, 20)
            }
        }
    }

    private var satinAlButonu: some View {
        ArchiveButton(title: calisiyor ? "İşleniyor…" : "Pro'ya geç", systemImage: "checkmark.seal") {
            Task { await satinAl() }
        }
        .frame(maxWidth: .infinity)
        .disabled(calisiyor || pro.products.isEmpty)
        .opacity(pro.products.isEmpty ? 0.4 : 1)
    }

    private var altBaglantilar: some View {
        VStack(spacing: 10) {
            Button {
                Task { calisiyor = true; await pro.restore(); calisiyor = false
                    if pro.isPro { dismiss() } }
            } label: {
                Text("Satın alımları geri yükle")
                    .font(Typo.data(12)).foregroundStyle(Ink.kagit.opacity(0.7))
            }
            HStack(spacing: 18) {
                Link("Kullanım Koşulları", destination: ProStore.termsURL)
                Link("Gizlilik", destination: ProStore.privacyURL)
            }
            .font(Typo.data(11))
            .tint(Ink.kagit.opacity(0.6))
        }
        .padding(.top, 4)
    }

    private func satinAl() async {
        let product = seciliYillik ? pro.annual : pro.monthly
        guard let product else { return }
        calisiyor = true
        defer { calisiyor = false }
        switch await pro.purchase(product) {
        case .success: dismiss()
        case .pending: hata = "Satın alma onay bekliyor. Onaylandığında Pro açılacak."
        case .cancelled: break
        case .failed: hata = "Satın alma tamamlanamadı. Lütfen tekrar dene."
        }
    }

    private func denemeDemo() async {
        if await pro.tryDemoUnlock(code: demoCode) {
            dismiss()
        } else {
            hata = "Demo kodu geçersiz."
        }
    }
}

private struct PlanRow: View {
    let product: Product
    let period: String
    let secili: Bool
    let rozet: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: secili ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(secili ? Ink.muhur : Ink.kagit.opacity(0.4))
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(period == "yıl" ? "Yıllık" : "Aylık")
                            .font(Typo.data(15, weight: .medium)).foregroundStyle(Ink.kagit)
                        if let rozet {
                            Text(rozet)
                                .font(Typo.data(8, weight: .semibold)).kerning(0.5)
                                .foregroundStyle(Ink.murekkepKoyu)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Ink.pirinc)
                        }
                    }
                    Text("\(product.displayPrice) / \(period)")
                        .font(Typo.data(11)).foregroundStyle(Ink.kagit.opacity(0.6))
                        .monospacedDigit()
                }
                Spacer()
            }
            .padding(14)
            .background(Ink.murekkep, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(secili ? Ink.muhur : Ink.cizgi.opacity(0.6), lineWidth: secili ? 1.5 : 0.5))
        }
        .buttonStyle(PressableStyle())
    }
}
