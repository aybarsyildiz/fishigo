import SwiftUI

/// §6: double-rule specimen frame — a heavier outer rule with a thin inner rule.
/// Archival artifacts only; interactive controls use rounded corners instead.
struct DoubleRuleFrame: View {
    var color: Color = Ink.cizgi

    var body: some View {
        ZStack {
            Rectangle().strokeBorder(color, lineWidth: 1.5)
            Rectangle().strokeBorder(color.opacity(0.7), lineWidth: 0.5).padding(5)
        }
    }
}

/// §6: nautical-chart fragment — depth contours, soundings, position crosses.
/// Procedural and deterministic; sits far in the background at low contrast.
/// `ink` defaults to hairline blue for dark surfaces; pass murekkep for paper.
/// `ornaments` adds the compass rose + extra soundings (hook page density).
struct ChartFragment: View {
    var ink: Color = Ink.cizgi
    var ornaments: Bool = false

    var body: some View {
        Canvas { ctx, size in
            let ink = self.ink

            // Depth contours: three lazy iso-lines drifting across the frame.
            for (index, baseY) in [0.22, 0.48, 0.76].enumerated() {
                var contour = Path()
                let phase = Double(index) * 1.7
                var first = true
                for step in stride(from: -0.02, through: 1.02, by: 0.02) {
                    let x = step * size.width
                    let wave = sin(step * 5.2 + phase) * 10 + sin(step * 11.7 + phase * 2) * 4
                    let y = baseY * size.height + wave
                    if first {
                        contour.move(to: CGPoint(x: x, y: y))
                        first = false
                    } else {
                        contour.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                ctx.stroke(contour, with: .color(ink.opacity(0.5)), lineWidth: 0.7)
            }

            // Soundings — depth figures scattered like a survey sheet.
            let soundings: [(Double, Double, String)] = [
                (0.16, 0.14, "27"), (0.68, 0.10, "44"), (0.88, 0.34, "38"),
                (0.30, 0.36, "19"), (0.08, 0.58, "31"), (0.55, 0.62, "12"),
                (0.80, 0.68, "9"), (0.24, 0.86, "7"), (0.64, 0.90, "15"),
            ]
            for (fx, fy, label) in soundings {
                ctx.draw(
                    Text(label).font(Typo.data(9)).foregroundStyle(ink.opacity(0.75)),
                    at: CGPoint(x: fx * size.width, y: fy * size.height))
            }

            // Position crosses.
            for (fx, fy) in [(0.42, 0.20), (0.12, 0.40), (0.74, 0.46), (0.40, 0.72), (0.90, 0.84)] {
                let center = CGPoint(x: fx * size.width, y: fy * size.height)
                var cross = Path()
                cross.move(to: CGPoint(x: center.x - 4, y: center.y))
                cross.addLine(to: CGPoint(x: center.x + 4, y: center.y))
                cross.move(to: CGPoint(x: center.x, y: center.y - 4))
                cross.addLine(to: CGPoint(x: center.x, y: center.y + 4))
                ctx.stroke(cross, with: .color(ink.opacity(0.6)), lineWidth: 0.7)
            }

            if ornaments {
                // Extra soundings — a denser survey.
                let extra: [(Double, Double, String)] = [
                    (0.44, 0.08, "52"), (0.06, 0.26, "23"), (0.94, 0.20, "41"),
                    (0.48, 0.44, "17"), (0.10, 0.74, "11"), (0.86, 0.92, "6"),
                    (0.34, 0.60, "26"), (0.70, 0.30, "33"),
                ]
                for (fx, fy, label) in extra {
                    ctx.draw(
                        Text(label).font(Typo.data(8)).foregroundStyle(ink.opacity(0.55)),
                        at: CGPoint(x: fx * size.width, y: fy * size.height))
                }

                // Compass rose, top-right.
                let center = CGPoint(x: size.width * 0.84, y: size.height * 0.13)
                let radius: CGFloat = 26
                ctx.stroke(
                    Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
                    with: .color(ink.opacity(0.7)), lineWidth: 0.8)
                ctx.stroke(
                    Path(ellipseIn: CGRect(x: center.x - radius * 0.62, y: center.y - radius * 0.62, width: radius * 1.24, height: radius * 1.24)),
                    with: .color(ink.opacity(0.5)), lineWidth: 0.5)
                for i in 0..<8 {
                    let angle = CGFloat(i) * .pi / 4
                    let long = i.isMultiple(of: 2)
                    let inner: CGFloat = long ? 4 : radius * 0.62
                    var spoke = Path()
                    spoke.move(to: CGPoint(x: center.x + cos(angle) * inner, y: center.y + sin(angle) * inner))
                    spoke.addLine(to: CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius))
                    ctx.stroke(spoke, with: .color(ink.opacity(long ? 0.8 : 0.45)), lineWidth: long ? 0.9 : 0.5)
                }
                ctx.draw(
                    Text("K").font(Typo.data(8, weight: .medium)).foregroundStyle(ink.opacity(0.85)),
                    at: CGPoint(x: center.x, y: center.y - radius - 8))
            }
        }
        .allowsHitTesting(false)
    }
}
