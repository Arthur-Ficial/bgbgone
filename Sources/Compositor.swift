import Foundation
import CoreGraphics
import CoreImage
import BgBgOneCore

enum Compositor {

    /// Compose the masked foreground with the chosen background and return a final CGImage.
    /// For .transparent, the masked image itself is the result.
    static func compose(
        masked: CGImage,
        mask: CGImage,
        background: Background,
        bgFit: BgFit,
        originalSize: CGSize
    ) throws -> CGImage {
        switch background {
        case .transparent:
            return masked

        case .solidColor(let rgba):
            return try compositeOverSolid(masked: masked, rgba: rgba)

        case .image(let path):
            return try compositeOverImage(masked: masked, bgPath: path, fit: bgFit)
        }
    }

    private static func compositeOverSolid(masked: CGImage, rgba: RGBA) throws -> CGImage {
        let w = masked.width
        let h = masked.height
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: w, height: h,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: cs,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw BgBgOneError.frameworkError("cannot create compositing context")
        }
        ctx.setFillColor(red: CGFloat(rgba.r), green: CGFloat(rgba.g), blue: CGFloat(rgba.b), alpha: CGFloat(rgba.a))
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        ctx.draw(masked, in: CGRect(x: 0, y: 0, width: w, height: h))
        guard let out = ctx.makeImage() else {
            throw BgBgOneError.frameworkError("cannot composite over solid colour")
        }
        return out
    }

    private static func compositeOverImage(masked: CGImage, bgPath: String, fit: BgFit) throws -> CGImage {
        let bg = try ImageLoader.load(bgPath)
        let w = masked.width
        let h = masked.height
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: w, height: h,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: cs,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw BgBgOneError.frameworkError("cannot create compositing context")
        }
        let bgRect = fitRect(
            content: CGSize(width: bg.width, height: bg.height),
            canvas: CGSize(width: w, height: h),
            fit: fit
        )
        ctx.draw(bg, in: bgRect)
        ctx.draw(masked, in: CGRect(x: 0, y: 0, width: w, height: h))
        guard let out = ctx.makeImage() else {
            throw BgBgOneError.frameworkError("cannot composite over image background")
        }
        return out
    }

    private static func fitRect(content: CGSize, canvas: CGSize, fit: BgFit) -> CGRect {
        switch fit {
        case .cover:
            let s = max(canvas.width / content.width, canvas.height / content.height)
            let w = content.width * s
            let h = content.height * s
            return CGRect(x: (canvas.width - w) / 2, y: (canvas.height - h) / 2, width: w, height: h)
        case .contain:
            let s = min(canvas.width / content.width, canvas.height / content.height)
            let w = content.width * s
            let h = content.height * s
            return CGRect(x: (canvas.width - w) / 2, y: (canvas.height - h) / 2, width: w, height: h)
        case .center:
            return CGRect(
                x: (canvas.width - content.width) / 2,
                y: (canvas.height - content.height) / 2,
                width: content.width,
                height: content.height
            )
        case .tile:
            // Tile mode is approximated by `cover` for now; true tiling is a v0.0.x followup.
            let s = max(canvas.width / content.width, canvas.height / content.height)
            let w = content.width * s
            let h = content.height * s
            return CGRect(x: (canvas.width - w) / 2, y: (canvas.height - h) / 2, width: w, height: h)
        }
    }
}
