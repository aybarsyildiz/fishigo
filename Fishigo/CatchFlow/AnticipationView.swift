import SwiftUI

/// §7 ANTICIPATION: a taut misina trembles and the bobber dips while
/// recognition runs. Communicates "something is on the line" — never a spinner.
/// Reduce Motion: line goes still, caption pulses (crossfade-class motion only).
struct AnticipationView: View {
    let photo: UIImage?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 180, height: 180)
                    .clipped()
                    .overlay(Rectangle().strokeBorder(Ink.cizgi, lineWidth: 1))
                    .opacity(0.85)
            }

            if Motion.reduceMotion {
                StillLine()
                    .frame(height: 150)
            } else {
                TimelineView(.animation) { timeline in
                    LineTensionCanvas(time: timeline.date.timeIntervalSinceReferenceDate)
                }
                .frame(height: 150)
            }

            PulsingCaption(text: "TÜR TEŞHİS EDİLİYOR")

            Spacer()
            Spacer()
        }
        .padding(24)
    }
}

/// The trembling line + dipping bobber, redrawn per frame.
private struct LineTensionCanvas: View {
    let time: TimeInterval

    var body: some View {
        Canvas { ctx, size in
            let topX = size.width / 2
            // Bobber dips: slow breathing + occasional sharper tug.
            let breathe = sin(time * 1.6) * 3
            let tug = max(0, sin(time * 0.7)) // 0…1 envelope
            let dip = pow(max(0, sin(time * 5.1)), 6) * 14 * tug
            let bobberY = size.height * 0.62 + breathe + dip

            // Taut misina from top edge to bobber, trembling laterally.
            let tremble = sin(time * 23) * 1.6 + sin(time * 41) * 0.8
            var line = Path()
            line.move(to: CGPoint(x: topX, y: 0))
            line.addQuadCurve(
                to: CGPoint(x: topX, y: bobberY - 12),
                control: CGPoint(x: topX + tremble * 4, y: bobberY * 0.5))
            ctx.stroke(line, with: .color(Ink.kagit.opacity(0.55)), lineWidth: 1)

            // Bobber: paper body, muhur cap — the screen's single accent.
            let bobber = CGRect(x: topX - 9, y: bobberY - 12, width: 18, height: 24)
            let cap = Path(ellipseIn: CGRect(x: bobber.minX, y: bobber.minY, width: 18, height: 13))
            let body = Path(ellipseIn: CGRect(x: bobber.minX, y: bobber.minY + 8, width: 18, height: 16))
            ctx.fill(body, with: .color(Ink.kagit))
            ctx.fill(cap, with: .color(Ink.muhur))

            // Water line the bobber sits in.
            var water = Path()
            let waterY = size.height * 0.72
            water.move(to: CGPoint(x: size.width * 0.15, y: waterY))
            for x in stride(from: size.width * 0.15, through: size.width * 0.85, by: 6) {
                let y = waterY + sin((x / 14) + time * 2.4) * 1.6
                water.addLine(to: CGPoint(x: x, y: y))
            }
            ctx.stroke(water, with: .color(Ink.cizgi), lineWidth: 1)
        }
    }
}

/// Reduce Motion variant: the same scene, still.
private struct StillLine: View {
    var body: some View {
        Canvas { ctx, size in
            let topX = size.width / 2
            let bobberY = size.height * 0.62
            var line = Path()
            line.move(to: CGPoint(x: topX, y: 0))
            line.addLine(to: CGPoint(x: topX, y: bobberY - 12))
            ctx.stroke(line, with: .color(Ink.kagit.opacity(0.55)), lineWidth: 1)
            let cap = Path(ellipseIn: CGRect(x: topX - 9, y: bobberY - 12, width: 18, height: 13))
            let body = Path(ellipseIn: CGRect(x: topX - 9, y: bobberY - 4, width: 18, height: 16))
            ctx.fill(body, with: .color(Ink.kagit))
            ctx.fill(cap, with: .color(Ink.muhur))
            var water = Path()
            let waterY = size.height * 0.72
            water.move(to: CGPoint(x: size.width * 0.15, y: waterY))
            water.addLine(to: CGPoint(x: size.width * 0.85, y: waterY))
            ctx.stroke(water, with: .color(Ink.cizgi), lineWidth: 1)
        }
    }
}

private struct PulsingCaption: View {
    let text: String
    @State private var dim = false

    var body: some View {
        Text(text)
            .font(Typo.data(12))
            .kerning(2)
            .foregroundStyle(Ink.kagit.opacity(dim ? 0.35 : 0.7))
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: dim)
            .onAppear { dim = true }
    }
}
