import SwiftUI

/// Generic engraving silhouettes, one per body type — drawn as Paths so the
/// uncaught state can render as dotted engraving (§6) and the caught state as
/// solid ink. Fish face left, normalized to the given rect.
struct FishSilhouette: Shape {
    let tip: Species.Siluet

    func path(in rect: CGRect) -> Path {
        var p = Path()
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }

        switch tip {
        case .uzun:
            // Fusiform — lüfer, palamut, levrek.
            p.move(to: pt(0.03, 0.50))
            p.addQuadCurve(to: pt(0.72, 0.30), control: pt(0.30, 0.10))
            p.addLine(to: pt(0.95, 0.16))
            p.addQuadCurve(to: pt(0.95, 0.84), control: pt(0.84, 0.50))
            p.addLine(to: pt(0.72, 0.70))
            p.addQuadCurve(to: pt(0.03, 0.50), control: pt(0.30, 0.90))
            p.closeSubpath()

        case .oval:
            // Deep-bodied — sparids, groupers.
            p.move(to: pt(0.04, 0.52))
            p.addQuadCurve(to: pt(0.66, 0.24), control: pt(0.22, 0.02))
            p.addLine(to: pt(0.94, 0.12))
            p.addQuadCurve(to: pt(0.94, 0.88), control: pt(0.82, 0.50))
            p.addLine(to: pt(0.66, 0.76))
            p.addQuadCurve(to: pt(0.04, 0.52), control: pt(0.22, 0.98))
            p.closeSubpath()

        case .yassi:
            // Flatfish — kalkan, dil, vatoz.
            p.move(to: pt(0.04, 0.50))
            p.addQuadCurve(to: pt(0.56, 0.10), control: pt(0.16, 0.10))
            p.addQuadCurve(to: pt(0.82, 0.50), control: pt(0.80, 0.24))
            p.addLine(to: pt(0.96, 0.40))
            p.addLine(to: pt(0.96, 0.60))
            p.addLine(to: pt(0.82, 0.50))
            p.addQuadCurve(to: pt(0.56, 0.90), control: pt(0.80, 0.76))
            p.addQuadCurve(to: pt(0.04, 0.50), control: pt(0.16, 0.90))
            p.closeSubpath()

        case .yilansi:
            // Elongate — müren, zargana, gelincik.
            p.move(to: pt(0.02, 0.58))
            p.addQuadCurve(to: pt(0.50, 0.42), control: pt(0.24, 0.34))
            p.addQuadCurve(to: pt(0.97, 0.50), control: pt(0.76, 0.52))
            p.addQuadCurve(to: pt(0.50, 0.58), control: pt(0.76, 0.62))
            p.addQuadCurve(to: pt(0.02, 0.66), control: pt(0.24, 0.52))
            p.closeSubpath()

        case .kafadan:
            // Cephalopod — mantle left, arms trailing right.
            p.move(to: pt(0.04, 0.50))
            p.addQuadCurve(to: pt(0.30, 0.28), control: pt(0.08, 0.28))
            p.addQuadCurve(to: pt(0.58, 0.36), control: pt(0.48, 0.28))
            p.addQuadCurve(to: pt(0.58, 0.64), control: pt(0.64, 0.50))
            p.addQuadCurve(to: pt(0.30, 0.72), control: pt(0.48, 0.72))
            p.addQuadCurve(to: pt(0.04, 0.50), control: pt(0.08, 0.72))
            p.closeSubpath()
            // Arms as thin tapering strands.
            for (startY, endY, bend) in [(0.40, 0.30, 0.30), (0.48, 0.46, 0.55), (0.56, 0.62, 0.50), (0.62, 0.76, 0.32)] {
                p.move(to: pt(0.58, startY))
                p.addQuadCurve(to: pt(0.94, endY), control: pt(0.78, bend))
                p.addQuadCurve(to: pt(0.58, startY + 0.04), control: pt(0.78, bend + 0.08))
                p.closeSubpath()
            }
        }
        return p
    }
}

/// The two §6 rendering states for a silhouette.
struct SilhouetteView: View {
    let tip: Species.Siluet
    let caught: Bool

    var body: some View {
        if caught {
            // Inked specimen on paper.
            FishSilhouette(tip: tip)
                .fill(Ink.murekkep)
        } else {
            // Dotted engraving on ink.
            FishSilhouette(tip: tip)
                .stroke(
                    Ink.kagit.opacity(0.45),
                    style: StrokeStyle(lineWidth: 1.1, lineCap: .round, dash: [0.1, 3.2]))
        }
    }
}
