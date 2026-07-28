import SwiftUI

/// The 9:16 specimen card (§2.1-6). Designed at 360×640 pt, rasterized at 3×
/// for a 1080×1920 story image.
///
/// `progress` (0…1) is the v1.1 video seam: the view is a pure function of
/// (spec, progress), so an animated export only has to render frames at
/// increasing progress values — no rewrite. Static export passes 1.
struct ShareCardView: View {
    let spec: ShareCardSpec
    var progress: CGFloat = 1

    private var frameColor: Color {
        spec.rarity.hasBrassAccent ? Ink.pirinc : Ink.murekkep.opacity(0.8)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM y"
        return formatter
    }()

    var body: some View {
        ZStack {
            // Chart paper
            Ink.kagit
            ChartFragment(ink: Ink.murekkep)
                .opacity(0.14)

            VStack(spacing: 0) {
                Text("SEYİR ARŞİVİ")
                    .font(Typo.data(9, weight: .medium))
                    .kerning(3)
                    .foregroundStyle(Ink.murekkep.opacity(0.5))
                    .padding(.top, 34)

                Text(spec.displayName)
                    .font(Typo.display(34))
                    .foregroundStyle(Ink.murekkep)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.top, 10)
                    .padding(.horizontal, 40)

                Text(spec.latin)
                    .font(Typo.latin(14))
                    .foregroundStyle(Ink.murekkep.opacity(0.6))
                    .padding(.top, 2)

                if spec.rarity.hasBrassAccent {
                    Text("— \(spec.rarity.rawValue.localizedUppercase) —")
                        .font(Typo.data(9, weight: .medium))
                        .kerning(3)
                        .foregroundStyle(Ink.pirinc)
                        .padding(.top, 6)
                }

                // Photo plate
                photoPlate
                    .padding(.top, 16)

                // The signature ruler graphic
                RulerGraphic(lengthCm: spec.lengthCm)
                    .frame(width: 288, height: 58)
                    .padding(.top, 18)

                // Stats strip
                statsStrip
                    .padding(.top, 14)

                Spacer(minLength: 0)

                // Footer
                HStack {
                    Text("BALIKDEKS \(spec.deksCaught)/\(spec.deksTotal)")
                        .font(Typo.data(10, weight: .medium))
                        .kerning(1.5)
                        .foregroundStyle(Ink.murekkep.opacity(0.6))
                        .monospacedDigit()
                    Spacer()
                    Text("FISHIGO")
                        .font(Typo.data(10, weight: .semibold))
                        .kerning(3)
                        .foregroundStyle(Ink.kagit)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Ink.murekkep)
                }
                .padding(.horizontal, 34)
                .padding(.bottom, 34)
            }
        }
        .frame(width: 360, height: 640)
        .overlay(DoubleRuleFrame(color: frameColor).padding(14))
    }

    private var photoPlate: some View {
        Group {
            if let photo = spec.photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Ink.murekkep
                    SilhouetteView(tip: spec.siluet, caught: false)
                        .frame(height: 90)
                        .padding(.horizontal, 40)
                }
            }
        }
        .frame(width: 288, height: 236)
        .clipped()
        .overlay(Rectangle().strokeBorder(Ink.murekkep.opacity(0.85), lineWidth: 1.2))
        .overlay(Rectangle().strokeBorder(Ink.murekkep.opacity(0.4), lineWidth: 0.5).padding(4))
        .overlay(alignment: .topTrailing) {
            if spec.isFirstOfSpecies {
                IlkYakalayisStamp()
                    .scaleEffect(stampScale)
                    .opacity(stampOpacity)
                    .padding(10)
            }
        }
    }

    /// Video-path joints: the stamp lands late in the timeline.
    private var stampScale: CGFloat {
        let t = min(max((progress - 0.8) / 0.2, 0), 1)
        return 2.1 - 1.1 * t
    }

    private var stampOpacity: CGFloat {
        progress > 0.8 ? 1 : 0
    }

    private var statsStrip: some View {
        HStack(spacing: 0) {
            stat("BOY", "\(spec.lengthCm) CM")
            divider
            stat("TARİH", Self.dateFormatter.string(from: spec.date).localizedUppercase)
            if let il = spec.il {
                divider
                stat("YER", il.localizedUppercase)
            }
            if spec.released {
                divider
                stat("", "SALINDI")
            }
        }
        .padding(.horizontal, 34)
    }

    private var divider: some View {
        Rectangle()
            .fill(Ink.murekkep.opacity(0.25))
            .frame(width: 1, height: 22)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            if !label.isEmpty {
                Text(label)
                    .font(Typo.data(7))
                    .kerning(1)
                    .foregroundStyle(Ink.murekkep.opacity(0.5))
            }
            Text(value)
                .font(Typo.data(11, weight: .medium))
                .foregroundStyle(Ink.murekkep)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}

/// The cm ruler with the specimen's length marked in muhur — the card's
/// single accent (the stamp shares the budget only on first catches).
struct RulerGraphic: View {
    let lengthCm: Int

    var body: some View {
        Canvas { ctx, size in
            let maxCm = max(Int((Double(lengthCm) * 1.25 / 5).rounded(.up)) * 5, 20)
            let ppc = size.width / CGFloat(maxCm)
            let baseline = size.height - 14
            let labelStep = maxCm >= 80 ? 20 : 10
            let minorStep = ppc < 2.6 ? 5 : 1

            for cm in stride(from: 0, through: maxCm, by: minorStep) {
                let x = CGFloat(cm) * ppc
                let major = cm % labelStep == 0
                let mid = cm % 5 == 0
                let height: CGFloat = major ? 16 : (mid ? 11 : 6)
                var tick = Path()
                tick.move(to: CGPoint(x: x, y: baseline))
                tick.addLine(to: CGPoint(x: x, y: baseline - height))
                ctx.stroke(
                    tick,
                    with: .color(Ink.murekkep.opacity(major ? 0.85 : (mid ? 0.6 : 0.35))),
                    lineWidth: major ? 1 : 0.6)
                if major {
                    ctx.draw(
                        Text("\(cm)").font(Typo.data(8)).foregroundStyle(Ink.murekkep.opacity(0.6)),
                        at: CGPoint(x: x, y: baseline + 8))
                }
            }

            var base = Path()
            base.move(to: CGPoint(x: 0, y: baseline))
            base.addLine(to: CGPoint(x: size.width, y: baseline))
            ctx.stroke(base, with: .color(Ink.murekkep.opacity(0.85)), lineWidth: 1)

            // The catch, marked.
            let markX = min(CGFloat(lengthCm) * ppc, size.width - 1)
            var needle = Path()
            needle.move(to: CGPoint(x: markX, y: baseline + 2))
            needle.addLine(to: CGPoint(x: markX, y: baseline - 24))
            ctx.stroke(needle, with: .color(Ink.muhur), lineWidth: 1.6)

            var arrow = Path()
            arrow.move(to: CGPoint(x: markX - 4, y: baseline - 24))
            arrow.addLine(to: CGPoint(x: markX + 4, y: baseline - 24))
            arrow.addLine(to: CGPoint(x: markX, y: baseline - 18))
            arrow.closeSubpath()
            ctx.fill(arrow, with: .color(Ink.muhur))

            let labelX = min(max(markX, 16), size.width - 24)
            ctx.draw(
                Text("\(lengthCm) CM").font(Typo.data(10, weight: .semibold)).foregroundStyle(Ink.muhur),
                at: CGPoint(x: labelX, y: baseline - 34))
        }
    }
}
