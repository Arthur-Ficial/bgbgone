import CoreGraphics
import Foundation
import BgBgOneCore

enum ImageTransforms {
    static func downscaleIfNeeded(_ image: CGImage, maxMegapixels: Double?) throws -> CGImage {
        guard let maxMegapixels, maxMegapixels > 0 else {
            return image
        }
        let pixels = Double(image.width * image.height)
        let maxPixels = maxMegapixels * 1_000_000.0
        guard pixels > maxPixels else {
            return image
        }
        let scale = sqrt(maxPixels / pixels)
        let width = max(1, Int((Double(image.width) * scale).rounded(.down)))
        let height = max(1, Int((Double(image.height) * scale).rounded(.down)))

        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: cs,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw BgBgOneError.frameworkError(
                ErrorCodes.frameworkCGContextFail,
                "cannot create output resize context"
            )
        }
        ctx.clear(CGRect(x: 0, y: 0, width: width, height: height))
        ctx.interpolationQuality = .high
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let out = ctx.makeImage() else {
            throw BgBgOneError.frameworkError(
                ErrorCodes.frameworkResizeFail,
                "cannot resize output"
            )
        }
        return out
    }
}
