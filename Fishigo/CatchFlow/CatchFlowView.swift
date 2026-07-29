import SwiftUI

/// Hosts the catch flow — renders whatever phase the state machine is in.
/// Phase changes animate as crossfade+slide; Reduce Motion drops the slide.
struct CatchFlowView: View {
    @Environment(AppModel.self) private var app
    @State private var model: CatchFlowModel?

    var body: some View {
        ZStack {
            Ink.murekkepKoyu.ignoresSafeArea()

            if let model {
                phaseView(model)
                    .id(model.phase)
                    .transition(Motion.reduceMotion
                        ? .opacity
                        : .opacity.combined(with: .move(edge: .trailing)))
                    .animation(Motion.honoring(Motion.transition), value: model.phase)
            }
        }
        .task {
            if model == nil { model = CatchFlowModel(app: app) }
        }
    }

    @ViewBuilder
    private func phaseView(_ model: CatchFlowModel) -> some View {
        switch model.phase {
        case .foto:
            PhotoPickView(model: model)
        case .tanima:
            AnticipationView(photo: model.photo)
        case .onay:
            ConfirmView(model: model)
        case .fotoYok:
            NoFishView(model: model)
        case .hata:
            NetworkErrorView(model: model)
        case .kota:
            QuotaWallView(model: model)
        case .olcum:
            DetailsView(model: model)
        case .acilis:
            RevealView(model: model)
        case .kaydedildi:
            SavedView(model: model)
        }
    }
}
