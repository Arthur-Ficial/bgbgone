import CoreGraphics
import Foundation
import BgBgOneCore

enum ImageTransforms {
    static func position(_ image: CGImage, scalePercent: Double?, position: ServerPosition?) throws -> CGImage {
        guard scalePercent != nil || position != nil else {
            return image
        }
        let canvasW = image.width
        let canvasH = image.height
        let scale = CGFloat(scalePercent ?? 1.0)
        let targetW = max(1, CGFloat(canvasW) * scale)
        let targetH = max(1, CGFloat(canvasH) * scale)
        let anchor = position ?? .center
        let centerX = CGFloat(anchor.x) * CGFloat(canvasW)
        let centerY = CGFloat(anchor.y) * CGFloat(canvasH)
        let rect = CGRect(x: centerX - targetW / 2, y: centerY - targetH / 2, width: targetW, height: targetH)

        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: canvasW,
            height: canvasH,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: cs,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw BgBgOneError.frameworkError("cannot create positioning context")
        }
        ctx.clear(CGRect(x: 0, y: 0, width: canvasW, height: canvasH))
        ctx.interpolationQuality = .high
        ctx.draw(image, in: rect)
        guard let out = ctx.makeImage() else {
            throw BgBgOneError.frameworkError("cannot position foreground")
        }
        return out
    }

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
            throw BgBgOneError.frameworkError("cannot create output resize context")
        }
        ctx.clear(CGRect(x: 0, y: 0, width: width, height: height))
        ctx.interpolationQuality = .high
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let out = ctx.makeImage() else {
            throw BgBgOneError.frameworkError("cannot resize output")
        }
        return out
    }
}
