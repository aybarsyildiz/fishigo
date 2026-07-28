import SwiftUI

/// §4 confirm rules: guven ≥ 0.8 → single confirm chip; below → candidate
/// chips + searchable full list. Correction logging comes with M5.
struct ConfirmView: View {
    let model: CatchFlowModel

    @State private var showList = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            if let photo = model.photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 220, height: 220)
                    .clipped()
                    .overlay(Rectangle().strokeBorder(Ink.cizgi, lineWidth: 1))
            }

            if let primary = model.candidates.first, model.sonuc?.isConfident == true {
                // Confident: one question, one chip.
                VStack(spacing: 16) {
                    Text("\(primary.ad) mi?")
                        .font(Typo.display(30))
                        .foregroundStyle(Ink.kagit)
                    Text(primary.latince)
                        .font(Typo.latin(15))
                        .foregroundStyle(Ink.kagit.opacity(0.6))

                    ArchiveButton(title: "Evet, \(primary.ad)", systemImage: "checkmark") {
                        model.confirm(primary)
                    }
                    .frame(maxWidth: 260)

                    Button {
                        Feel.shared.buttonTap()
                        showList = true
                    } label: {
                        Text("DEĞİŞTİR")
                            .font(Typo.data(12))
                            .kerning(1.5)
                            .foregroundStyle(Ink.kagit.opacity(0.6))
                            .padding(8)
                    }
                }
            } else {
                // Uncertain: candidates side by side + full list.
                VStack(spacing: 16) {
                    Text("Emin değilim —\nhangisi?")
                        .font(Typo.display(26))
                        .foregroundStyle(Ink.kagit)
                        .multilineTextAlignment(.center)

                    ForEach(model.candidates.prefix(3)) { species in
                        CandidateChip(species: species) {
                            model.confirm(species)
                        }
                    }
                    .frame(maxWidth: 280)

                    Button {
                        Feel.shared.buttonTap()
                        showList = true
                    } label: {
                        Text("LİSTEDEN ARA")
                            .font(Typo.data(12))
                            .kerning(1.5)
                            .foregroundStyle(Ink.kagit.opacity(0.6))
                            .padding(8)
                    }
                }
            }

            Spacer()
            Spacer()
        }
        .padding(24)
        .sheet(isPresented: $showList) {
            SpeciesListSheet { species in
                showList = false
                model.confirm(species)
            }
        }
    }
}

struct CandidateChip: View {
    let species: Species
    let action: () -> Void

    var body: some View {
        Button {
            Feel.shared.buttonTap()
            action()
        } label: {
            HStack {
                Text(species.ad)
                    .font(Typo.data(15, weight: .regular))
                    .foregroundStyle(Ink.murekkepKoyu)
                Spacer()
                Text(species.latince)
                    .font(Typo.latin(12))
                    .foregroundStyle(Ink.murekkepKoyu.opacity(0.55))
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Ink.kagit)
            .overlay(Rectangle().strokeBorder(Ink.cizgi.opacity(0.4), lineWidth: 0.5).padding(3))
        }
        .buttonStyle(PressableStyle())
    }
}

/// "Değiştir" fallback — the whole closed list, searchable.
struct SpeciesListSheet: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    let onPick: (Species) -> Void

    @State private var query = ""

    var body: some View {
        NavigationStack {
            List(app.species.search(query)) { species in
                Button {
                    Feel.shared.buttonTap()
                    onPick(species)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(species.ad)
                            .font(Typo.data(15))
                            .foregroundStyle(Ink.kagit)
                        Text(species.latince)
                            .font(Typo.latin(12))
                            .foregroundStyle(Ink.kagit.opacity(0.55))
                    }
                }
                .listRowBackground(Ink.murekkep)
            }
            .scrollContentBackground(.hidden)
            .background(Ink.murekkepKoyu)
            .searchable(text: $query, prompt: "Tür ara")
            .navigationTitle("Tür seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                        .foregroundStyle(Ink.kagit)
                }
            }
        }
        .presentationDetents([.large])
    }
}

/// balik_yok — friendly, zero blame, straight back to retry.
struct NoFishView: View {
    let model: CatchFlowModel

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "water.waves")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Ink.kagit.opacity(0.6))
            Text("Fotoğrafta balık\ngöremedim")
                .font(Typo.display(26))
                .foregroundStyle(Ink.kagit)
                .multilineTextAlignment(.center)
            Text("BALIĞI BİRAZ DAHA YAKINDAN DENE")
                .font(Typo.data(11))
                .kerning(1.5)
                .foregroundStyle(Ink.kagit.opacity(0.5))

            ArchiveButton(title: "Tekrar dene", systemImage: "arrow.counterclockwise") {
                model.retry()
            }
            .frame(maxWidth: 240)
            .padding(.top, 8)

            Spacer()
            Spacer()
        }
        .padding(24)
    }
}
