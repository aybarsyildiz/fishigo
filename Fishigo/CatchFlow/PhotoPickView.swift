import SwiftUI
import SwiftData
import PhotosUI

/// The HOOK — first thing an angler sees. An archive desk: chart fragment
/// underneath, the catch action as the centerpiece, live progress modules
/// below (deks fraction, last catch). M7 adds the streak and condition
/// modules to this same shelf.
struct PhotoPickView: View {
    let model: CatchFlowModel

    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
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

                Spacer(minLength: 0)

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

                // The shelf: live hook modules. M7 adds streak + koşullar here.
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        DeksHookModule()
                        LastCatchHookModule()
                    }
                    HStack(spacing: 10) {
                        RecordHookModule()
                        ThisMonthHookModule()
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(20)
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
    }
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

/// This month's outings — the habit meter until M7's real streak lands here.
private struct ThisMonthHookModule: View {
    @Environment(AppModel.self) private var app
    @Query private var records: [CatchRecord]

    private var thisMonth: Int {
        let calendar = Calendar.current
        let now = calendar.dateComponents([.year, .month], from: .now)
        return records.count { calendar.dateComponents([.year, .month], from: $0.date) == now }
    }

    var body: some View {
        Button {
            Feel.shared.buttonTap()
            app.tab = .defter
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                Text("BU AY")
                    .font(Typo.data(9, weight: .medium))
                    .kerning(1.5)
                    .foregroundStyle(Ink.kagit.opacity(0.45))
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(thisMonth)")
                        .font(Typo.data(22, weight: .medium))
                        .foregroundStyle(Ink.kagit)
                        .monospacedDigit()
                    Text("YAKALAYIŞ")
                        .font(Typo.data(10))
                        .foregroundStyle(Ink.kagit.opacity(0.5))
                }
                Text("SEFER SERİSİ M7'DE BURADA")
                    .font(Typo.data(8))
                    .kerning(0.5)
                    .foregroundStyle(Ink.kagit.opacity(0.3))
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
