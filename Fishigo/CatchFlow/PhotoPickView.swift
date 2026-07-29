import SwiftUI
import SwiftData
import PhotosUI

/// The HOOK — first thing an angler sees. An archive desk: chart fragment
/// underneath, the catch action as the centerpiece, live progress modules
/// below (deks fraction, last catch). M7 adds the streak and condition
/// modules to this same shelf.
struct PhotoPickView: View {
    @Environment(AppModel.self) private var app
    let model: CatchFlowModel

    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    /// Bucket mode: a whole-catch photo routed to bulk recognition.
    @State private var bucketItem: PhotosPickerItem?
    @State private var bucketImage: UIImage?
    @State private var showPaywall = false
    /// §2.1-11: the free-quota counter is always visible once known (-1 = unknown).
    @AppStorage("kalanTanima") private var kalanTanima = -1

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM EEEE"
        return formatter
    }()

    var body: some View {
        ZStack {
            ChartFragment(ornaments: true)
                .ignoresSafeArea()
                .opacity(0.55)

            ScrollView(showsIndicators: false) {
              VStack(spacing: 14) {
                // Ledger head
                VStack(spacing: 6) {
                    HStack {
                        Text("SEYİR ARŞİVİ")
                            .kerning(2)
                        Spacer()
                        Text(Self.dateFormatter.string(from: .now).localizedUppercase)
                            .kerning(1)
                    }
                    .font(Typo.data(10))
                    .foregroundStyle(Ink.kagit.opacity(0.45))
                    Rectangle()
                        .fill(Ink.cizgi.opacity(0.7))
                        .frame(height: 0.5)
                    LedgerLine()
                }
                .padding(.top, 8)

                // The catch plate — centerpiece
                VStack(spacing: 18) {
                    VStack(spacing: 10) {
                        Image(systemName: "fish")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(Ink.kagit.opacity(0.8))
                        Text("Balığını fotoğrafla")
                            .font(Typo.display(30))
                            .foregroundStyle(Ink.kagit)
                            .minimumScaleFactor(0.8)
                        Text("TÜRÜ OTOMATİK TEŞHİS EDİLİR")
                            .font(Typo.data(10))
                            .kerning(2)
                            .foregroundStyle(Ink.kagit.opacity(0.5))
                    }

                    VStack(spacing: 10) {
                        if cameraAvailable {
                            ArchiveButton(title: "Kamera", systemImage: "camera") {
                                showCamera = true
                            }
                        }
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            ArchiveButtonLabel(title: "Galeriden seç", systemImage: "photo.on.rectangle")
                        }
                        .simultaneousGesture(TapGesture().onEnded { Feel.shared.buttonTap() })

                        // Kova modu is a Pro feature. Free users see it with a
                        // brass lock that opens the paywall instead of the picker.
                        if app.pro.isPro {
                            PhotosPicker(selection: $bucketItem, matching: .images) {
                                bucketLabel(locked: false)
                            }
                            .simultaneousGesture(TapGesture().onEnded { Feel.shared.buttonTap() })
                        } else {
                            Button {
                                Feel.shared.buttonTap()
                                showPaywall = true
                            } label: { bucketLabel(locked: true) }
                            .buttonStyle(PressableStyle())
                        }
                    }
                    .frame(maxWidth: 250)

                    if kalanTanima >= 0 {
                        Text("BU AY KALAN TANIMA: \(kalanTanima)")
                            .font(Typo.data(9))
                            .kerning(1.5)
                            .foregroundStyle(kalanTanima == 0 ? Ink.muhur : Ink.kagit.opacity(0.4))
                            .monospacedDigit()
                    }
                }
                .padding(.vertical, 30)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
                .background(Ink.murekkep)
                .overlay(DoubleRuleFrame())

                // The shelf: every module is live data; koşullar gets full width.
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        DeksHookModule()
                        LastCatchHookModule()
                    }
                    HStack(spacing: 10) {
                        SeferSerisiModule()
                        RecordHookModule()
                    }
                    KosullarModule()
                    BugunModule()
                    ProNudge()
                    BosDondumBar()
                }
              }
              .padding(20)
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                Feel.shared.shutter()
                model.photoPicked(image)
            }
            .ignoresSafeArea()
        }
        .onChange(of: pickerItem) {
            guard let pickerItem else { return }
            Task {
                if let data = try? await pickerItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    model.photoPicked(image)
                }
                self.pickerItem = nil
            }
        }
        .onChange(of: bucketItem) {
            guard let bucketItem else { return }
            Task {
                if let data = try? await bucketItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    bucketImage = image
                }
                self.bucketItem = nil
            }
        }
        .fullScreenCover(item: $bucketImage) { image in
            BucketView(image: image)
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private func bucketLabel(locked: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: locked ? "lock" : "square.grid.2x2")
            Text("Kova modu · birden fazla balık")
                .font(Typo.data(11))
            if locked {
                Text("PRO")
                    .font(Typo.data(8, weight: .semibold)).kerning(1)
                    .foregroundStyle(Ink.pirinc)
            }
        }
        .foregroundStyle(Ink.kagit.opacity(0.65))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Ink.cizgi.opacity(0.7), style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
    }
}

extension UIImage: @retroactive Identifiable {
    public var id: ObjectIdentifier { ObjectIdentifier(self) }
}

/// Deks progress on the front door — the collection pull, one tap from filling it.
private struct DeksHookModule: View {
    @Environment(AppModel.self) private var app
    @Query private var records: [CatchRecord]

    private var caughtCount: Int { DeksProgress.caughtIds(records).count }

    var body: some View {
        Button {
            Feel.shared.buttonTap()
            app.tab = .deks
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                Text("BALIKDEKS")
                    .font(Typo.data(9, weight: .medium))
                    .kerning(1.5)
                    .foregroundStyle(Ink.kagit.opacity(0.45))
                Text("\(caughtCount) / \(app.species.all.count)")
                    .font(Typo.data(22, weight: .medium))
                    .foregroundStyle(Ink.kagit)
                    .monospacedDigit()
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Ink.cizgi.opacity(0.7))
                        Rectangle()
                            .fill(Ink.kagit)
                            .frame(width: geo.size.width * fraction)
                    }
                }
                .frame(height: 2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Ink.murekkep, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Ink.cizgi.opacity(0.6), lineWidth: 0.5))
        }
        .buttonStyle(PressableStyle())
    }

    private var fraction: CGFloat {
        let total = app.species.all.count
        guard total > 0 else { return 0 }
        return CGFloat(caughtCount) / CGFloat(total)
    }
}

/// Archive-ledger flavor line with live numbers: record count and next entry no.
private struct LedgerLine: View {
    @Query private var records: [CatchRecord]

    var body: some View {
        HStack {
            Text("DEFTER · \(records.count) KAYIT")
                .kerning(1)
            Spacer()
            Text("SIRADAKİ KAYIT NO. \(records.count + 1)")
                .kerning(1)
        }
        .font(Typo.data(8))
        .foregroundStyle(Ink.kagit.opacity(0.35))
        .monospacedDigit()
    }
}

/// Personal best across all species — the number to beat.
private struct RecordHookModule: View {
    @Environment(AppModel.self) private var app
    @Query private var records: [CatchRecord]

    private var best: CatchRecord? {
        records.max { $0.lengthCm < $1.lengthCm }
    }

    var body: some View {
        Button {
            Feel.shared.buttonTap()
            app.tab = .defter
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                Text("REKORUN")
                    .font(Typo.data(9, weight: .medium))
                    .kerning(1.5)
                    .foregroundStyle(Ink.kagit.opacity(0.45))
                if let best {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(best.lengthCm)")
                            .font(Typo.data(22, weight: .medium))
                            .foregroundStyle(Ink.pirinc)
                            .monospacedDigit()
                        Text("CM")
                            .font(Typo.data(10))
                            .foregroundStyle(Ink.kagit.opacity(0.5))
                    }
                    Text(name(best).localizedUppercase)
                        .font(Typo.data(9))
                        .kerning(0.5)
                        .foregroundStyle(Ink.kagit.opacity(0.55))
                        .lineLimit(1)
                } else {
                    Text("—")
                        .font(Typo.data(22, weight: .medium))
                        .foregroundStyle(Ink.kagit.opacity(0.35))
                    Text("KIRILMAYI BEKLİYOR")
                        .font(Typo.data(8))
                        .kerning(0.5)
                        .foregroundStyle(Ink.kagit.opacity(0.35))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Ink.murekkep, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Ink.cizgi.opacity(0.6), lineWidth: 0.5))
        }
        .buttonStyle(PressableStyle())
    }

    private func name(_ record: CatchRecord) -> String {
        app.species.species(id: record.speciesId)?.displayName(lengthCm: record.lengthCm) ?? record.speciesId
    }
}

/// §2.1-9 sefer serisi: weekly outing streak with a six-week tally row.
/// An outing = any catch OR any logged empty trip.
private struct SeferSerisiModule: View {
    @Environment(AppModel.self) private var app
    @Query private var records: [CatchRecord]
    @Query private var trips: [EmptyTrip]

    private var outings: [Date] {
        records.map(\.date) + trips.map(\.date)
    }

    var body: some View {
        Button {
            Feel.shared.buttonTap()
            app.tab = .defter
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                Text("SEFER SERİSİ")
                    .font(Typo.data(9, weight: .medium))
                    .kerning(1.5)
                    .foregroundStyle(Ink.kagit.opacity(0.45))
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Sefer.haftalikSeri(outings: outings))")
                        .font(Typo.data(22, weight: .medium))
                        .foregroundStyle(Ink.kagit)
                        .monospacedDigit()
                    Text("HAFTA")
                        .font(Typo.data(10))
                        .foregroundStyle(Ink.kagit.opacity(0.5))
                }
                HStack(spacing: 4) {
                    ForEach(Array(Sefer.sonHaftalar(6, outings: outings).enumerated()), id: \.offset) { _, dolu in
                        Rectangle()
                            .fill(dolu ? Ink.kagit : Color.clear)
                            .frame(width: 8, height: 8)
                            .overlay(Rectangle().strokeBorder(
                                dolu ? Ink.kagit : Ink.cizgi,
                                lineWidth: dolu ? 0 : 0.8))
                    }
                    Spacer()
                    Text(Sefer.buHaftaVar(outings: outings) ? "BU HAFTA ✓" : "BU HAFTA BEKLİYOR")
                        .font(Typo.data(7))
                        .kerning(0.5)
                        .foregroundStyle(Ink.kagit.opacity(0.4))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Ink.murekkep, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Ink.cizgi.opacity(0.6), lineWidth: 0.5))
        }
        .buttonStyle(PressableStyle())
    }
}

/// §2.1-9: logging a fishless day is one tap, and the copy thanks you for it.
/// Warning haptic, NEVER error — a fishless day is not a failure (§7).
private struct BosDondumBar: View {
    @Environment(AppModel.self) private var app
    @Query private var records: [CatchRecord]
    @Query private var trips: [EmptyTrip]

    var body: some View {
        let outings = records.map(\.date) + trips.map(\.date)
        if Sefer.bugunVar(outings: outings) {
            Text(trips.contains(where: { Calendar.current.isDateInToday($0.date) })
                ? "SEFER İŞLENDİ — BOŞ DÖNMEK DE BALIKÇILIKTIR"
                : "BUGÜNÜN SEFERİ DEFTERDE")
                .font(Typo.data(9))
                .kerning(1)
                .foregroundStyle(Ink.kagit.opacity(0.4))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        } else {
            Button {
                Feel.shared.emptyCatch()
                app.log.logEmptyTrip()
            } label: {
                Text("BOŞ DÖNDÜM · SEFERİ YİNE DE İŞLE")
                    .font(Typo.data(10))
                    .kerning(1.5)
                    .foregroundStyle(Ink.kagit.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Ink.cizgi.opacity(0.7), style: StrokeStyle(lineWidth: 1, dash: [2, 3])))
            }
            .buttonStyle(PressableStyle())
        }
    }
}

/// Latest specimen, straight into the defter.
private struct LastCatchHookModule: View {
    @Environment(AppModel.self) private var app
    @Query(sort: \CatchRecord.date, order: .reverse) private var records: [CatchRecord]

    private var last: CatchRecord? { records.first }

    var body: some View {
        Button {
            Feel.shared.buttonTap()
            app.tab = .defter
        } label: {
            HStack(spacing: 10) {
                Group {
                    if let data = last?.photoJPEG, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        FishSilhouette(tip: .uzun)
                            .stroke(
                                Ink.kagit.opacity(0.35),
                                style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [0.1, 3]))
                            .padding(8)
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(Ink.cizgi, lineWidth: 0.5))

                VStack(alignment: .leading, spacing: 4) {
                    Text("SON YAKALAYIŞ")
                        .font(Typo.data(9, weight: .medium))
                        .kerning(1.5)
                        .foregroundStyle(Ink.kagit.opacity(0.45))
                    if let last {
                        Text(displayName(last))
                            .font(Typo.data(14, weight: .medium))
                            .foregroundStyle(Ink.kagit)
                            .lineLimit(1)
                        Text("\(last.lengthCm) CM")
                            .font(Typo.data(10))
                            .foregroundStyle(Ink.kagit.opacity(0.55))
                            .monospacedDigit()
                    } else {
                        Text("Defter seni bekliyor")
                            .font(Typo.data(12))
                            .foregroundStyle(Ink.kagit.opacity(0.6))
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Ink.murekkep, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Ink.cizgi.opacity(0.6), lineWidth: 0.5))
        }
        .buttonStyle(PressableStyle())
    }

    private func displayName(_ record: CatchRecord) -> String {
        app.species.species(id: record.speciesId)?.displayName(lengthCm: record.lengthCm) ?? record.speciesId
    }
}

/// Shared archive-styled button. Press acknowledgment (haptic) fires on tap —
/// visual press state comes from the plain button style scale.
struct ArchiveButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button {
            Feel.shared.buttonTap()
            action()
        } label: {
            ArchiveButtonLabel(title: title, systemImage: systemImage)
        }
        .buttonStyle(PressableStyle())
    }
}

/// UI principle (owner feedback): archival ARTIFACTS (cards, frames, stamps)
/// stay square-ruled; INTERACTIVE controls get soft continuous corners so they
/// read as tappable, not as printed matter.
struct ArchiveButtonLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
            Text(title)
                .font(Typo.data(15, weight: .regular))
        }
        .foregroundStyle(Ink.murekkepKoyu)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Ink.kagit, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(Ink.cizgi.opacity(0.4), lineWidth: 0.5)
                .padding(3))
    }
}

/// <100 ms press acknowledgment: immediate scale on press, spring on release.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !Motion.reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(Motion.microSnappy, value: configuration.isPressed)
    }
}
