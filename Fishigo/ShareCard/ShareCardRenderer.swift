import SwiftUI

/// Rasterizes the specimen card for the share sheet.
///
/// v1.1 video path (no rewrite needed): call `renderImage(spec:progress:)`
/// per frame with increasing progress and feed the frames to
/// AVAssetWriter — the card view is a pure function of (spec, progress).
@MainActor
enum ShareCardRenderer {
    /// 360×640 design space × 3 = 1080×1920 story image.
    static func renderImage(spec: ShareCardSpec, progress: CGFloat = 1) -> UIImage? {
        let renderer = ImageRenderer(
            content: ShareCardView(spec: spec, progress: progress))
        renderer.scale = 3
        renderer.isOpaque = true
        return renderer.uiImage
    }
}
