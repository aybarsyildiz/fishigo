import SwiftUI
import PhotosUI

/// Flow entry: camera or gallery. The system PhotosPicker needs no permission;
/// the camera asks in-context with the Turkish rationale from Info.plist.
struct PhotoPickView: View {
    let model: CatchFlowModel

    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "fish")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(Ink.kagit.opacity(0.8))
                Text("Balığını fotoğrafla")
                    .font(Typo.display(28))
                    .foregroundStyle(Ink.kagit)
                Text("TÜRÜ OTOMATİK TEŞHİS EDİLİR")
                    .font(Typo.data(11))
                    .kerning(1.5)
                    .foregroundStyle(Ink.kagit.opacity(0.5))
            }
            .padding(36)
            .background(Ink.murekkep)
            .overlay(DoubleRuleFrame())

            VStack(spacing: 12) {
                if cameraAvailable {
                    ArchiveButton(title: "Kamera", systemImage: "camera") {
                        showCamera = true
                    }
                }
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    ArchiveButtonLabel(title: "Galeriden seç", systemImage: "photo.on.rectangle")
                }
                .simultaneousGesture(TapGesture().onEnded { Feel.shared.buttonTap() })
            }
            .frame(maxWidth: 280)

            Spacer()
            Spacer()
        }
        .padding(24)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                Feel.shared.shutter()
                model.photoPicked(image)
            }
            .ignoresSafeArea()
        }
        .onChange(of: pickerItem) {
            guard let pickerItem else { return }
            Task {
                if let data = try? await pickerItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    model.photoPicked(image)
                }
                self.pickerItem = nil
            }
        }
    }
}

/// Shared archive-styled button. Press acknowledgment (haptic) fires on tap —
/// visual press state comes from the plain button style scale.
struct ArchiveButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button {
            Feel.shared.buttonTap()
            action()
        } label: {
            ArchiveButtonLabel(title: title, systemImage: systemImage)
        }
        .buttonStyle(PressableStyle())
    }
}

struct ArchiveButtonLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
            Text(title)
                .font(Typo.data(15, weight: .regular))
        }
        .foregroundStyle(Ink.murekkepKoyu)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Ink.kagit)
        .overlay(Rectangle().strokeBorder(Ink.cizgi.opacity(0.4), lineWidth: 0.5).padding(3))
    }
}

/// <100 ms press acknowledgment: immediate scale on press, spring on release.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !Motion.reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(Motion.microSnappy, value: configuration.isPressed)
    }
}
