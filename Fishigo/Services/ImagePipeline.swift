import UIKit
import CryptoKit

/// §4 client spec: downscale to max 1024 px long edge, JPEG ~0.7 quality.
/// Used for the recognizer payload AND for stored catch photos, so what the
/// model saw is exactly what the log keeps.
enum ImagePipeline {
    static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func recognitionJPEG(from image: UIImage, maxDimension: CGFloat = 1024, quality: CGFloat = 0.7) -> Data? {
        let longEdge = max(image.size.width, image.size.height)
        guard longEdge > maxDimension else {
            return image.jpegData(compressionQuality: quality)
        }
        let scale = maxDimension / longEdge
        let target = CGSize(width: (image.size.width * scale).rounded(),
                            height: (image.size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: quality)
    }
}
