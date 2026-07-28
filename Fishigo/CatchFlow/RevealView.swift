import SwiftUI

/// §7 reveal choreography, steps 3–6: the card flips from its back, the
/// length COUNTS up with ticks, and — on a first catch — the İLK YAKALAYIŞ
/// stamp lands with the heavy thunk. Total envelope ~2.3 s (within 1.8–3.0).
/// Tap-to-skip is armed only after the first-ever viewing.
struct RevealView: View {
    let model: CatchFlowModel

    @AppStorage("acilisGoruldu") private var seenBefore = false

    @State private var flip: Double = 0          // 0 = back, 180 = front
    @State private var shownLength = 0           // counting number
    @State private var stampVisible = false
    @State private var controlsVisible = false
    @State private var ceremony: Task<Void, Never>?

    private var isFirst: Bool { model.isFirstOfSpecies }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                SpecimenCardBack(rarity: model.secilenTur?.nadirlik ?? .yaygin)
                    .opacity(flip < 90 ? 1 : 0)
                    .rotation3DEffect(.degrees(flip), axis: (x: 0, y: 1, z: 0))

                SpecimenCardView(
                    photo: model.photo,
                    name: model.displayName,
                    latin: model.secilenTur?.latince ?? "",
                    lengthText: "\(shownLength)",
                    date: .now,
                    released: model.released,
                    legality: model.legality,
                    rarity: model.secilenTur?.nadirlik ?? .yaygin)
                    .overlay(alignment: .topTrailing) {
                        if stampVisible {
                            IlkYakalayisStamp()
                                .padding(14)
                                .transition(.identity)
                        }
                    }
                    .opacity(flip >= 90 ? 1 : 0)
                    .rotation3DEffect(.degrees(flip - 180), axis: (x: 0, y: 1, z: 0))
            }

            VStack(spacing: 4) {
                if model.legality != .bilgiYok {
                    Text("KAYNAK: \(model.mevzuatKaynagi)")
                        .lineLimit(2)
                    if let limit = model.gunlukLimit {
                        Text("GÜNLÜK LİMİT: \(limit.localizedUppercase)")
                    }
                }
                Text(LegalityCopy.disclaimer)
            }
            .font(Typo.data(9))
            .foregroundStyle(Ink.kagit.opacity(0.4))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)

            ArchiveButton(title: "Deftere kaydet", systemImage: "book.closed") {
                model.saveCatch()
            }
            .frame(maxWidth: 260)
            .opacity(controlsVisible ? 1 : 0)
            .disabled(!controlsVisible)

            Spacer()
        }
        .padding(24)
        .contentShape(Rectangle())
        .onTapGesture {
            if seenBefore { skipToEnd() }
        }
        .task {
            ceremony = Task { await runCeremony() }
            await ceremony?.value
        }
    }

    // MARK: Choreography

    private func runCeremony() async {
        // Beat on the card back — the pause is the point.
        Feel.shared.cardLift()
        if await sleepOrCancelled(450) { return }

        // Flip. First catches get the ceremony haptic ramp under the flip.
        withAnimation(Motion.honoring(.spring(response: 0.55, dampingFraction: 0.8))) {
            flip = 180
        }
        if isFirst { Feel.shared.newSpeciesCeremony() }
        if await sleepOrCancelled(600) { return }

        // Numbers count, never appear (§7). ~24 quick steps with ticks.
        let target = model.lengthCm
        let start = max(0, target - 24)
        shownLength = start
        for value in stride(from: start, through: target, by: 1) {
            shownLength = value
            if value % 2 == 0 { Feel.shared.rulerTick() }
            if await sleepOrCancelled(22) { return }
        }

        if await sleepOrCancelled(250) { return }

        // Stamp: one accent per ceremony.
        if isFirst {
            withAnimation(Motion.honoring(Motion.stamp)) {
                stampVisible = true
            }
            Feel.shared.stamp()
            if await sleepOrCancelled(450) { return }
        } else if let best = model.personalBest, model.lengthCm > best {
            // Repeat species but a new personal record. Visual record
            // treatment (pirinc accents) lands with M2's real history.
            Feel.shared.record()
            if await sleepOrCancelled(300) { return }
        }

        finishCeremony()
    }

    /// Returns true when the ceremony was skipped/cancelled.
    private func sleepOrCancelled(_ ms: Int) async -> Bool {
        do {
            try await Task.sleep(for: .milliseconds(ms))
            return false
        } catch {
            return true
        }
    }

    private func skipToEnd() {
        ceremony?.cancel()
        withAnimation(.easeInOut(duration: 0.15)) {
            flip = 180
            shownLength = model.lengthCm
            stampVisible = isFirst
            controlsVisible = true
        }
    }

    private func finishCeremony() {
        withAnimation(Motion.honoring(Motion.micro)) {
            controlsVisible = true
        }
        if !seenBefore { seenBefore = true }
    }
}

/// Card back: engraved archive mark on ink. Brass rules for epik/efsanevi.
struct SpecimenCardBack: View {
    let rarity: Rarity

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "fish")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundStyle(Ink.kagit.opacity(0.35))
            Text("FISHIGO ARŞİVİ")
                .font(Typo.data(11))
                .kerning(3)
                .foregroundStyle(Ink.kagit.opacity(0.45))
        }
        .frame(width: 320, height: 430)
        .background(Ink.murekkep)
        .overlay(DoubleRuleFrame(color: rarity.hasBrassAccent ? Ink.pirinc : Ink.cizgi))
    }
}

/// §7: İLK YAKALAYIŞ stamp — scale 2.1→1.0 (Motion.stamp curve applied by the
/// caller), ~9° rotation, muhur red, double ring.
struct IlkYakalayisStamp: View {
    var body: some View {
        Text("İLK YAKALAYIŞ")
            .font(Typo.data(12, weight: .semibold))
            .kerning(1.5)
            .foregroundStyle(Ink.muhur)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .overlay(
                ZStack {
                    Rectangle().strokeBorder(Ink.muhur, lineWidth: 2)
                    Rectangle().strokeBorder(Ink.muhur.opacity(0.7), lineWidth: 1).padding(3)
                })
            .rotationEffect(.degrees(-9))
            .opacity(0.92)
            .transition(.scale(scale: 2.1).combined(with: .opacity))
    }
}

/// Saved confirmation — quiet, plus the deks progress pull. A completed
/// size-name chain gets its banner and haptic here (§8). Sharing lives one
/// tap away, never forced.
struct SavedView: View {
    let model: CatchFlowModel

    @State private var showShare = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "checkmark.seal")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Ink.kagit.opacity(0.8))
            Text("Deftere işlendi")
                .font(Typo.display(28))
                .foregroundStyle(Ink.kagit)
            Text("DEFTERDE \(model.logCount) KAYIT")
                .font(Typo.data(11))
                .kerning(1.5)
                .foregroundStyle(Ink.kagit.opacity(0.5))

            HStack(spacing: 8) {
                Text("BALIKDEKS \(model.deksCaughtCount)/\(model.deksTotal)")
                if model.savedRecord?.isFirstOfSpecies == true {
                    Text("· YENİ TÜR")
                        .foregroundStyle(Ink.pirinc)
                }
            }
            .font(Typo.data(11, weight: .medium))
            .kerning(1.5)
            .foregroundStyle(Ink.kagit.opacity(0.7))
            .monospacedDigit()

            if model.lineJustCompleted {
                Text("BOY SERİSİ TAMAMLANDI")
                    .font(Typo.data(11, weight: .semibold))
                    .kerning(2)
                    .foregroundStyle(Ink.pirinc)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .overlay(DoubleRuleFrame(color: Ink.pirinc))
                    .onAppear { Feel.shared.newSpeciesCeremony() }
            }

            ArchiveButton(title: "Yeni yakalayış", systemImage: "camera") {
                model.reset()
            }
            .frame(maxWidth: 240)
            .padding(.top, 10)

            Button {
                Feel.shared.buttonTap()
                showShare = true
            } label: {
                Text("KARTI PAYLAŞ")
                    .font(Typo.data(12))
                    .kerning(1.5)
                    .foregroundStyle(Ink.kagit.opacity(0.6))
                    .padding(8)
            }

            Spacer()
            Spacer()
        }
        .padding(24)
        .sheet(isPresented: $showShare) {
            if let record = model.savedRecord {
                SharePreviewSheet(record: record)
            }
        }
    }
}
