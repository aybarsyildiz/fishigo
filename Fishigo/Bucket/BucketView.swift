import SwiftUI

/// Bucket-mode UI: recognition → editable list → bulk save. Presented as a
/// sheet from the catch screen so the main single-catch flow is untouched.
struct BucketView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    let image: UIImage

    @State private var model: BucketModel?
    @State private var showList = false

    var body: some View {
        ZStack {
            Ink.murekkepKoyu.ignoresSafeArea()
            if let model {
                content(model)
            }
        }
        .task {
            if model == nil { model = BucketModel(app: app, image: image) }
        }
    }

    @ViewBuilder
    private func content(_ model: BucketModel) -> some View {
        switch model.phase {
        case .tanima:
            AnticipationView(photo: model.photo)
        case .liste:
            listeGorunumu(model)
        case .hata:
            durumEkrani("Bağlantı kurulamadı", "wifi.slash", "Tekrar dene") {
                self.model = BucketModel(app: app, image: image)
            }
        case .kota:
            durumEkrani("Bu ayki tanıma hakkın doldu", "hourglass", "Kapat") { dismiss() }
        case .kaydedildi(let adet):
            durumEkrani("\(adet) balık deftere işlendi", "checkmark.seal", "Bitti") { dismiss() }
        }
    }

    private func listeGorunumu(_ model: BucketModel) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("KOVA MODU · \(model.satirlar.count) BALIK")
                    .font(Typo.data(11, weight: .medium))
                    .kerning(1.5)
                    .foregroundStyle(Ink.kagit.opacity(0.6))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Ink.kagit.opacity(0.6))
                        .padding(8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            if model.satirlar.isEmpty {
                Spacer()
                Text("BALIK BULUNAMADI —\nLİSTEYE ELLE EKLEYEBİLİRSİN")
                    .font(Typo.data(11))
                    .kerning(1)
                    .foregroundStyle(Ink.kagit.opacity(0.5))
                    .multilineTextAlignment(.center)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(model.satirlar) { row in
                            BucketRow(
                                name: model.species(row)?.ad ?? row.turId,
                                latin: model.species(row)?.latince ?? "",
                                guven: row.guven,
                                onChange: {
                                    changeTarget = row.id
                                    showList = true
                                },
                                onRemove: { model.remove(row.id) })
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }

            VStack(spacing: 10) {
                Button {
                    Feel.shared.buttonTap()
                    changeTarget = nil
                    showList = true
                } label: {
                    Text("+ BALIK EKLE")
                        .font(Typo.data(12))
                        .kerning(1.5)
                        .foregroundStyle(Ink.kagit.opacity(0.6))
                        .padding(8)
                }

                ArchiveButton(title: "Hepsini deftere kaydet", systemImage: "book.closed") {
                    model.saveAll()
                }
                .frame(maxWidth: 280)
                .disabled(model.satirlar.isEmpty)
                .opacity(model.satirlar.isEmpty ? 0.4 : 1)

                Text("Boy girilmez — kova modu hızlı kayıt içindir.")
                    .font(Typo.data(9))
                    .foregroundStyle(Ink.kagit.opacity(0.4))
            }
            .padding(.bottom, 24)
        }
        .sheet(isPresented: $showList) {
            SpeciesListSheet { species in
                showList = false
                if let target = changeTarget {
                    model.changeSpecies(target, to: species)
                } else {
                    model.addSpecies(species)
                }
                changeTarget = nil
            }
        }
    }

    @State private var changeTarget: UUID?

    private func durumEkrani(_ title: String, _ icon: String, _ button: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(Ink.kagit.opacity(0.7))
            Text(title)
                .font(Typo.display(24))
                .foregroundStyle(Ink.kagit)
                .multilineTextAlignment(.center)
            ArchiveButton(title: button, systemImage: "arrow.right") { action() }
                .frame(maxWidth: 220)
                .padding(.top, 8)
            Spacer()
            Spacer()
        }
        .padding(24)
    }
}

struct BucketRow: View {
    let name: String
    let latin: String
    let guven: Double
    let onChange: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(Typo.data(15, weight: .medium))
                    .foregroundStyle(Ink.murekkepKoyu)
                if !latin.isEmpty {
                    Text(latin)
                        .font(Typo.latin(11))
                        .foregroundStyle(Ink.murekkepKoyu.opacity(0.55))
                }
            }
            Spacer()
            if guven < 0.8 {
                Text("?")
                    .font(Typo.data(13, weight: .semibold))
                    .foregroundStyle(Ink.muhur)
            }
            Button(action: onChange) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 14))
                    .foregroundStyle(Ink.murekkepKoyu.opacity(0.6))
                    .padding(6)
            }
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Ink.murekkepKoyu.opacity(0.5))
                    .padding(6)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Ink.kagit, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
