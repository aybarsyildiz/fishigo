import SwiftUI

/// First-launch introduction (3 screens max, §M8). A guide fish swims from
/// page to page — every stroke of its tail is a haptic tick, so the app's
/// feel-language is taught before the first real tap. No permission prompts
/// here (§9: those stay in-context, at the first catch).
struct OnboardingView: View {
    let onDone: () -> Void

    @State private var page = 0
    @State private var stampVisible = false

    private let pageCount = 3

    var body: some View {
        ZStack {
            Ink.murekkepKoyu.ignoresSafeArea()
            ChartFragment()
                .ignoresSafeArea()
                .opacity(0.4)

            VStack(spacing: 0) {
                GuideFish(page: page, pageCount: pageCount)
                    .frame(height: 90)
                    .padding(.top, 30)

                TabView(selection: $page) {
                    OnboardPage(
                        title: "Fotoğrafla,\ngerisi bizde",
                        caption: "TÜR OTOMATİK TEŞHİS EDİLİR — BOYU CETVELLE SEN GİRERSİN") {
                        Image(systemName: "camera")
                            .font(.system(size: 44, weight: .light))
                            .foregroundStyle(Ink.kagit.opacity(0.85))
                    }
                    .tag(0)

                    OnboardPage(
                        title: "Balıkdeks'ini\ndoldur",
                        caption: "69 TÜR SENİ BEKLİYOR — HER İLK YAKALAYIŞ DAMGALANIR") {
                        ZStack {
                            SilhouetteView(tip: .uzun, caught: false)
                                .frame(width: 130, height: 54)
                            if stampVisible {
                                IlkYakalayisStamp()
                                    .scaleEffect(0.8)
                                    .offset(x: 30, y: -34)
                            }
                        }
                    }
                    .tag(1)

                    OnboardPage(
                        title: "Noktan\nsende kalır",
                        caption: "KONUM SENDE KALIR · YAKALAYIŞLARIN iCLOUD'A GİZLİCE YEDEKLENİR") {
                        SpotMarker(isFirst: true)
                            .scaleEffect(1.6)
                    }
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page rules
                HStack(spacing: 8) {
                    ForEach(0..<pageCount, id: \.self) { index in
                        Rectangle()
                            .fill(index == page ? Ink.kagit : Ink.cizgi)
                            .frame(width: index == page ? 26 : 14, height: 2)
                    }
                }
                .animation(Motion.honoring(Motion.micro), value: page)
                .padding(.bottom, 22)

                ArchiveButton(
                    title: page < pageCount - 1 ? "Devam" : "Başla",
                    systemImage: page < pageCount - 1 ? "arrow.right" : "fish"
                ) {
                    if page < pageCount - 1 {
                        withAnimation(Motion.honoring(Motion.transition)) {
                            page += 1
                        }
                    } else {
                        onDone()
                    }
                }
                .frame(maxWidth: 250)
                .padding(.bottom, 34)
            }
        }
        .onChange(of: page) {
            swimStrokes()
            if page == 1 && !stampVisible {
                Task {
                    try? await Task.sleep(for: .milliseconds(650))
                    withAnimation(Motion.honoring(Motion.stamp)) {
                        stampVisible = true
                    }
                    Feel.shared.stamp()
                }
            }
        }
    }

    /// The guide fish "swims" — a short run of tail-stroke ticks.
    private func swimStrokes() {
        Task {
            for _ in 0..<4 {
                Feel.shared.deksCascadeTick()
                try? await Task.sleep(for: .milliseconds(70))
            }
        }
    }
}

/// The guide — an inked fish that crosses the header as pages advance,
/// with a gentle idle bob (still under Reduce Motion).
private struct GuideFish: View {
    let page: Int
    let pageCount: Int

    @State private var bob = false

    var body: some View {
        GeometryReader { geo in
            let usable = geo.size.width - 140
            let x = 70 + usable * CGFloat(page) / CGFloat(max(pageCount - 1, 1))

            FishSilhouette(tip: .uzun)
                .fill(Ink.kagit)
                .frame(width: 92, height: 38)
                .scaleEffect(x: -1) // swims left→right
                .rotationEffect(.degrees(bob ? 2.5 : -2.5))
                .offset(y: bob ? -4 : 4)
                .position(x: x, y: geo.size.height / 2)
                .animation(Motion.honoring(.spring(response: 0.7, dampingFraction: 0.75)), value: page)
        }
        .onAppear {
            guard !Motion.reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                bob = true
            }
        }
    }
}

private struct OnboardPage<Figure: View>: View {
    let title: String
    let caption: String
    @ViewBuilder let figure: Figure

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            figure
                .frame(height: 90)

            Text(title)
                .font(Typo.display(32))
                .foregroundStyle(Ink.kagit)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)

            Rectangle()
                .fill(Ink.cizgi)
                .frame(width: 110, height: 1)

            Text(caption)
                .font(Typo.data(10))
                .kerning(1.5)
                .foregroundStyle(Ink.kagit.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.horizontal, 40)

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}
