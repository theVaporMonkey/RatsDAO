import Foundation
import UIKit
import AVFoundation

/// Helpers for turning UIImage / video URLs into the JPEG payloads that
/// `ClaudeService` ships to the Anthropic API.
enum MediaService {
    /// Maximum dimension (pixels) we send to Claude. Keeps payload size
    /// reasonable over cellular while preserving enough detail to read
    /// gauges, displays, and water clarity.
    static let maxDimension: CGFloat = 1600

    static func jpeg(from image: UIImage, quality: CGFloat = 0.8) -> Data? {
        resize(image, to: maxDimension).jpegData(compressionQuality: quality)
    }

    /// Grabs a representative frame from a video (the 1s mark, clamped to
    /// video length) so Claude can "see" the situation even though it can't
    /// ingest video directly.
    static func thumbnail(for videoURL: URL) async -> UIImage? {
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: maxDimension, height: maxDimension)

        let duration = try? await asset.load(.duration)
        let seconds = max(0.0, min(1.0, CMTimeGetSeconds(duration ?? .zero) - 0.1))
        let target = CMTime(seconds: seconds, preferredTimescale: 600)

        return await withCheckedContinuation { cont in
            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: target)]) { _, cg, _, _, _ in
                if let cg { cont.resume(returning: UIImage(cgImage: cg)) }
                else { cont.resume(returning: nil) }
            }
        }
    }

    private static func resize(_ image: UIImage, to maxSide: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxSide else { return image }
        let scale = maxSide / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
