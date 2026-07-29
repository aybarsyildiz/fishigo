import SwiftUI

/// The tasteful in-app "ad" — for Pro itself, not a third-party network.
/// Appears on the hook shelf for free users only (hidden once subscribed).
/// This is the upgrade pressure the brief's premium archive aesthetic can carry
/// without ATT prompts, SKAdNetwork, or banner clutter.
struct ProNudge: View {
    @Environment(AppModel.self) private var app
    @State private var show = false

    var body: some View {
        if !app.pro.isPro {
            Button {
                Feel.shared.buttonTap()
                show = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "rosette")
                        .font(.system(size: 18))
                        .foregroundStyle(Ink.muhur)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Fishigo Pro")
                            .font(Typo.data(14, weight: .medium))
                            .foregroundStyle(Ink.kagit)
                        Text("SINIRSIZ TANIMA · KOVA MODU · ÖNERİLER")
                            .font(Typo.data(8)).kerning(0.5)
                            .foregroundStyle(Ink.kagit.opacity(0.5))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Ink.kagit.opacity(0.4))
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(Ink.murekkep, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Ink.muhur.opacity(0.5), lineWidth: 1))
            }
            .buttonStyle(PressableStyle())
            .sheet(isPresented: $show) { PaywallView() }
        }
    }
}

/// A Pro settings row for the conditions/settings sheet — either "manage" (Pro)
/// or "upgrade" (free). Lets users subscribe anywhere, not just at the wall.
struct ProSettingsRow: View {
    @Environment(AppModel.self) private var app
    @State private var show = false

    var body: some View {
        Button {
            Feel.shared.buttonTap()
            if app.pro.isPro {
                UIApplication.shared.open(ProStore.manageURL)
            } else {
                show = true
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "rosette").foregroundStyle(app.pro.isPro ? Ink.pirinc : Ink.muhur)
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.pro.isPro ? "Fishigo Pro · Etkin" : "Fishigo Pro'ya geç")
                        .font(Typo.data(13)).foregroundStyle(Ink.kagit)
                    Text(app.pro.isPro ? "ABONELİĞİ YÖNET" : "SINIRSIZ TANIMA VE DAHA FAZLASI")
                        .font(Typo.data(8)).kerning(1)
                        .foregroundStyle(Ink.kagit.opacity(0.45))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Ink.kagit.opacity(0.4))
            }
        }
        .padding(14)
        .background(Ink.murekkep)
        .overlay(DoubleRuleFrame())
        .sheet(isPresented: $show) { PaywallView() }
    }
}
