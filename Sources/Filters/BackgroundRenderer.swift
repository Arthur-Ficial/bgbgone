import Foundation
import CoreGraphics
import CoreImage
import ImageIO
import BgBgOneCore

/// Renders a `Background` value into a CGImage at the canvas size. Used by
/// the `FilterPipeline` so background-layer filters have a real CIImage
/// to operate on.
public enum BackgroundRenderer {
    public static func render(
        _ background: Background,
        bgFit: BgFit,
        canvas: CGRect
    ) throws -> CGImage {
        switch background {
        case .transparent:
            return try transparentCanvas(canvas)
        case .solidColor(let rgba):
            return try solidColor(rgba, canvas: canvas)
        case .image(let path):
            return try imageBackground(path: path, bgFit: bgFit, canvas: canvas)
        }
    }

    private static func transparentCanvas(_ canvas: CGRect) throws -> CGImage {
        let w = Int(canvas.width), h = Int(canvas.height)
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil, width: w, height: h,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: cs,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkCGContextFail, "bg renderer: transparent context")
        }
        ctx.clear(CGRect(x: 0, y: 0, width: w, height: h))
        guard let cg = ctx.makeImage() else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkCGImageFail, "bg renderer: transparent makeImage")
        }
        return cg
    }

    private static func solidColor(_ rgba: RGBA, canvas: CGRect) throws -> CGImage {
        let w = Int(canvas.width), h = Int(canvas.height)
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil, width: w, height: h,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: cs,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkCGContextFail, "bg renderer: solid context")
        }
        ctx.setFillColor(red: CGFloat(rgba.r), green: CGFloat(rgba.g), blue: CGFloat(rgba.b), alpha: CGFloat(rgba.a))
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        guard let cg = ctx.makeImage() else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkCGImageFail, "bg renderer: solid makeImage")
        }
        return cg
    }

    private static func imageBackground(path: String, bgFit: BgFit, canvas: CGRect) throws -> CGImage {
        let bg = try ImageLoader.load(path)
        let w = Int(canvas.width), h = Int(canvas.height)
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil, width: w, height: h,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: cs,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkCGContextFail, "bg renderer: image context")
        }
        let rect = fitRect(content: CGSize(width: bg.width, height: bg.height), canvas: CGSize(width: w, height: h), fit: bgFit)
        switch bgFit {
        case .tile:
            tile(bg, into: ctx, canvas: CGSize(width: w, height: h))
        default:
            ctx.draw(bg, in: rect)
        }
        guard let cg = ctx.makeImage() else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkCGImageFail, "bg renderer: image makeImage")
        }
        return cg
    }

    private static func fitRect(content: CGSize, canvas: CGSize, fit: BgFit) -> CGRect {
        switch fit {
        case .cover:
            let s = max(canvas.width / content.width, canvas.height / content.height)
            return CGRect(x: (canvas.width - content.width * s) / 2, y: (canvas.height - content.height * s) / 2, width: content.width * s, height: content.height * s)
        case .contain:
            let s = min(canvas.width / content.width, canvas.height / content.height)
            return CGRect(x: (canvas.width - content.width * s) / 2, y: (canvas.height - content.height * s) / 2, width: content.width * s, height: content.height * s)
        case .center, .tile:
            return CGRect(x: (canvas.width - content.width) / 2, y: (canvas.height - content.height) / 2, width: content.width, height: content.height)
        }
    }

    private static func tile(_ bg: CGImage, into ctx: CGContext, canvas: CGSize) {
        let tw = max(CGFloat(bg.width), 1), th = max(CGFloat(bg.height), 1)
        var startX = (canvas.width - tw) / 2, startY = (canvas.height - th) / 2
        while startX > 0 { startX -= tw }
        while startY > 0 { startY -= th }
        var y = startY
        while y < canvas.height {
            var x = startX
            while x < canvas.width {
                ctx.draw(bg, in: CGRect(x: x, y: y, width: tw, height: th))
                x += tw
            }
            y += th
        }
    }
}
