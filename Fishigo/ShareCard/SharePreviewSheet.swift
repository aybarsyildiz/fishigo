import SwiftUI

/// Preview + one-tap share (§2.1-6). The preview IS the rendered export —
/// what you see is byte-for-byte what leaves the phone.
struct SharePreviewSheet: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    let record: CatchRecord

    @State private var rendered: UIImage?

    var body: some View {
        ZStack {
            Ink.murekkepKoyu.ignoresSafeArea()

            VStack(spacing: 18) {
                HStack {
                    Text("PAYLAŞIM KARTI")
                        .font(Typo.data(11, weight: .medium))
                        .kerning(2)
                        .foregroundStyle(Ink.kagit.opacity(0.5))
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Ink.kagit.opacity(0.6))
                            .padding(8)
                    }
                }
                .padding(.top, 16)

                if let rendered {
                    Image(uiImage: rendered)
                        .resizable()
                        .scaledToFit()
                        .overlay(Rectangle().strokeBorder(Ink.cizgi.opacity(0.6), lineWidth: 0.5))
                        .frame(maxHeight: .infinity)
                } else {
                    Spacer()
                    Text("KART BASILIYOR…")
                        .font(Typo.data(11))
                        .kerning(2)
                        .foregroundStyle(Ink.kagit.opacity(0.4))
                    Spacer()
                }

                if let rendered {
                    ShareLink(
                        item: Image(uiImage: rendered),
                        preview: SharePreview("Yakalayış", image: Image(uiImage: rendered))
                    ) {
                        ArchiveButtonLabel(title: "Paylaş", systemImage: "square.and.arrow.up")
                    }
                    .simultaneousGesture(TapGesture().onEnded { Feel.shared.buttonTap() })
                    .frame(maxWidth: 260)
                }

                Text("Kartta konum olarak yalnızca il görünür. Noktan sende kalır.")
                    .font(Typo.data(9))
                    .foregroundStyle(Ink.kagit.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 16)
            }
            .padding(.horizontal, 24)
        }
        .task {
            await prepare()
        }
    }

    private func prepare() async {
        // Late province resolution for records saved before geocoding finished
        // (or from older app versions).
        if record.il == nil, let coordinate = record.coordinate,
           let il = await ProvinceResolver.il(for: coordinate) {
            app.log.attachProvince(il, to: record)
        }
        rendered = ShareCardRenderer.renderImage(spec: .make(record: record, app: app))
    }
}
