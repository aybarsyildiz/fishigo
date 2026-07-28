import SwiftUI

/// Length (ruler with tick haptics), released toggle, optional note.
/// The live size-name preview is the curiosity detail: slide past 18 cm and
/// "Çinekop" becomes "Sarıkanat" before your eyes.
struct DetailsView: View {
    @Bindable var model: CatchFlowModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 6) {
                Text(model.displayName)
                    .font(Typo.display(32))
                    .foregroundStyle(Ink.kagit)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: model.displayName)
                if let tur = model.secilenTur, tur.hasEvolutionLine {
                    Text("BOYA GÖRE AD DEĞİŞİR")
                        .font(Typo.data(10))
                        .kerning(1.5)
                        .foregroundStyle(Ink.pirinc)
                }
            }

            VStack(spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(model.lengthCm)")
                        .font(Typo.data(44, weight: .semibold))
                        .foregroundStyle(Ink.kagit)
                        .monospacedDigit()
                    Text("CM")
                        .font(Typo.data(14))
                        .foregroundStyle(Ink.kagit.opacity(0.6))
                }
                RulerInput(valueCm: $model.lengthCm)
            }
            .padding(.vertical, 12)
            .background(Ink.murekkep)
            .overlay(DoubleRuleFrame())

            VStack(spacing: 14) {
                Toggle(isOn: $model.released) {
                    Text("Denize geri bıraktım")
                        .font(Typo.data(14))
                        .foregroundStyle(Ink.kagit)
                }
                .tint(Ink.cizgi)
                .onChange(of: model.released) {
                    Feel.shared.buttonTap()
                }

                TextField("Not (isteğe bağlı)", text: $model.note, axis: .vertical)
                    .font(Typo.data(14))
                    .foregroundStyle(Ink.kagit)
                    .lineLimit(2...3)
                    .padding(12)
                    .background(Ink.murekkep, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Ink.cizgi, lineWidth: 0.5))
            }

            ArchiveButton(title: "Kartı aç", systemImage: "seal") {
                model.measurementDone()
            }
            .frame(maxWidth: 260)

            Spacer()
        }
        .padding(24)
    }
}

/// Horizontal cm ruler: drag to slide, one selection tick per centimeter (§7),
/// snaps to the nearest cm on release. The muhur needle is this screen's
/// single accent.
struct RulerInput: View {
    @Binding var valueCm: Int
    var range: ClosedRange<Int> = 5...150

    private let ppc: CGFloat = 9 // points per centimeter

    @State private var continuous: CGFloat = 0
    @State private var dragBase: CGFloat?

    var body: some View {
        Canvas { ctx, size in
            let midX = size.width / 2
            let baseline = size.height - 22
            let halfVisible = Int(size.width / ppc / 2) + 2
            let center = Int(continuous.rounded())

            for cm in (center - halfVisible)...(center + halfVisible) {
                guard range.contains(cm) else { continue }
                let x = midX + (CGFloat(cm) - continuous) * ppc
                let height: CGFloat = cm.isMultiple(of: 10) ? 28 : (cm.isMultiple(of: 5) ? 19 : 11)
                var tick = Path()
                tick.move(to: CGPoint(x: x, y: baseline))
                tick.addLine(to: CGPoint(x: x, y: baseline - height))
                ctx.stroke(tick, with: .color(Ink.kagit.opacity(cm.isMultiple(of: 5) ? 0.85 : 0.45)), lineWidth: 1)

                if cm.isMultiple(of: 10) {
                    ctx.draw(
                        Text("\(cm)").font(Typo.data(10)).foregroundStyle(Ink.kagit.opacity(0.6)),
                        at: CGPoint(x: x, y: baseline + 11))
                }
            }

            var needle = Path()
            needle.move(to: CGPoint(x: midX, y: baseline + 4))
            needle.addLine(to: CGPoint(x: midX, y: baseline - 34))
            ctx.stroke(needle, with: .color(Ink.muhur), lineWidth: 2)
        }
        .frame(height: 78)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { gesture in
                    if dragBase == nil { dragBase = continuous }
                    let proposed = (dragBase ?? continuous) - gesture.translation.width / ppc
                    continuous = proposed.clamped(to: CGFloat(range.lowerBound)...CGFloat(range.upperBound))
                    let rounded = Int(continuous.rounded())
                    if rounded != valueCm {
                        valueCm = rounded
                        Feel.shared.rulerTick()
                    }
                }
                .onEnded { _ in
                    dragBase = nil
                    withAnimation(Motion.honoring(Motion.microSnappy)) {
                        continuous = CGFloat(valueCm)
                    }
                })
        .onAppear { continuous = CGFloat(valueCm) }
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
