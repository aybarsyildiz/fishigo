import SwiftUI

/// M1 specimen card — user photo on chart paper, engraved framing, stats
/// strip, legality chip. M4 replaces this with the full share-renderer
/// (ruler graphic, chart-fragment background, 9:16 export); keep the props
/// stable so the swap doesn't touch the reveal.
struct SpecimenCardView: View {
    let photo: UIImage?
    let name: String
    let latin: String
    let lengthText: String
    let date: Date
    let released: Bool
    let legality: LegalityStatus
    let rarity: Rarity

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM y"
        return formatter
    }()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 3) {
                Text(name)
                    .font(Typo.display(26))
                    .foregroundStyle(Ink.murekkep)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(latin)
                    .font(Typo.latin(13))
                    .foregroundStyle(Ink.murekkep.opacity(0.6))
            }
            .padding(.top, 18)
            .padding(.bottom, 12)

            // Photo plate
            Group {
                if let photo {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                } else {
                    Ink.cizgi.opacity(0.2)
                }
            }
            .frame(width: 272, height: 200)
            .clipped()
            .overlay(Rectangle().strokeBorder(Ink.murekkep.opacity(0.8), lineWidth: 1))

            // Stats strip
            HStack(spacing: 0) {
                stat("BOY", "\(lengthText) CM")
                divider
                stat("TARİH", Self.dateFormatter.string(from: date).localizedUppercase)
                if released {
                    divider
                    stat("", "SALINDI")
                }
            }
            .padding(.vertical, 12)

            LegalityChip(status: legality)
                .padding(.bottom, 16)
        }
        .frame(width: 320)
        .background(Ink.kagit)
        .overlay(DoubleRuleFrame(color: rarity.hasBrassAccent ? Ink.pirinc : Ink.murekkep.opacity(0.75)))
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
                    .font(Typo.data(8))
                    .kerning(1)
                    .foregroundStyle(Ink.murekkep.opacity(0.5))
            }
            Text(value)
                .font(Typo.data(12, weight: .medium))
                .foregroundStyle(Ink.murekkep)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }
}

/// §5 result chip. bilgiYok stays neutral cizgi; violations use muhur — on the
/// reveal screen the stamp is the accent, so a muhur chip can only co-occur
/// with a non-first catch (no stamp). Acceptable; revisit in M6 if it clashes.
struct LegalityChip: View {
    let status: LegalityStatus

    var body: some View {
        switch status {
        case .serbest:
            chip("SERBEST", foreground: Ink.kagit, background: Ink.murekkep, border: Ink.murekkep)
        case .boyAlti(let minCm):
            chip("BOY LİMİTİ ALTI · MİN \(minCm) CM", foreground: Ink.muhur, background: .clear, border: Ink.muhur)
        case .donemYasagi:
            chip("DÖNEM YASAĞI", foreground: Ink.kagit, background: Ink.muhur, border: Ink.muhur)
        case .bilgiYok:
            chip("KURAL BİLGİSİ YOK", foreground: Ink.murekkep.opacity(0.55), background: .clear, border: Ink.cizgi.opacity(0.6))
        }
    }

    private func chip(_ text: String, foreground: Color, background: Color, border: Color) -> some View {
        Text(text)
            .font(Typo.data(10, weight: .medium))
            .kerning(1)
            .foregroundStyle(foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(background)
            .overlay(Rectangle().strokeBorder(border, lineWidth: 1))
    }
}
