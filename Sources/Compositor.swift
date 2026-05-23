import Foundation
import CoreGraphics
import BgBgOneCore

enum Compositor {

    /// Compose the alpha-masked foreground with the chosen background.
    static func compose(masked: CGImage, background: Background, bgFit: BgFit, dropShadow: Bool, shadowOpacity: Double = 0.50) throws -> CGImage {
        switch background {
        case .transparent:
            return try compositeTransparent(masked: masked, dropShadow: dropShadow, shadowOpacity: shadowOpacity)
        case .solidColor(let rgba):
            return try compositeOverSolid(masked: masked, rgba: rgba, dropShadow: dropShadow, shadowOpacity: shadowOpacity)
        case .image(let path):
            return try compositeOverImage(masked: masked, bgPath: path, fit: bgFit, dropShadow: dropShadow, shadowOpacity: shadowOpacity)
        }
    }

    private static func makeContext(width: Int, height: Int) throws -> CGContext {
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
                "cannot create compositing context"
            )
        }
        return ctx
    }

    private static func compositeTransparent(masked: CGImage, dropShadow: Bool, shadowOpacity: Double) throws -> CGImage {
        let w = masked.width
        let h = masked.height
        let ctx = try makeContext(width: w, height: h)
        ctx.clear(CGRect(x: 0, y: 0, width: w, height: h))
        drawForeground(masked, in: ctx, dropShadow: dropShadow, shadowOpacity: shadowOpacity)
        guard let out = ctx.makeImage() else {
            throw BgBgOneError.frameworkError(
                ErrorCodes.frameworkComposeFail,
                "cannot composite transparent output"
            )
        }
        return out
    }

    private static func compositeOverSolid(masked: CGImage, rgba: RGBA, dropShadow: Bool, shadowOpacity: Double) throws -> CGImage {
        let w = masked.width
        let h = masked.height
        let ctx = try makeContext(width: w, height: h)
        ctx.setFillColor(red: CGFloat(rgba.r), green: CGFloat(rgba.g), blue: CGFloat(rgba.b), alpha: CGFloat(rgba.a))
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        drawForeground(masked, in: ctx, dropShadow: dropShadow, shadowOpacity: shadowOpacity)
        guard let out = ctx.makeImage() else {
            throw BgBgOneError.frameworkError(
                ErrorCodes.frameworkComposeFail,
                "cannot composite over solid colour"
            )
        }
        return out
    }

    private static func compositeOverImage(masked: CGImage, bgPath: String, fit: BgFit, dropShadow: Bool, shadowOpacity: Double) throws -> CGImage {
        let bg = try ImageLoader.load(bgPath)
        let w = masked.width
        let h = masked.height
        let ctx = try makeContext(width: w, height: h)
        drawBackground(bg, in: ctx, canvas: CGSize(width: w, height: h), fit: fit)
        drawForeground(masked, in: ctx, dropShadow: dropShadow, shadowOpacity: shadowOpacity)
        guard let out = ctx.makeImage() else {
            throw BgBgOneError.frameworkError(
                ErrorCodes.frameworkComposeFail,
                "cannot composite over image background"
            )
        }
        return out
    }

    private static func drawForeground(_ masked: CGImage, in ctx: CGContext, dropShadow: Bool, shadowOpacity: Double) {
        let rect = CGRect(x: 0, y: 0, width: masked.width, height: masked.height)
        if dropShadow {
            let longest = CGFloat(max(masked.width, masked.height))
            let blur = max(4, min(28, longest * 0.025))
            let offsetY = -max(2, CGFloat(masked.height) * 0.018)
            ctx.saveGState()
            ctx.setShadow(
                offset: CGSize(width: 0, height: offsetY),
                blur: blur,
                color: CGColor(red: 0, green: 0, blue: 0, alpha: max(0, min(1, shadowOpacity)))
            )
            ctx.draw(masked, in: rect)
            ctx.restoreGState()
        }
        ctx.draw(masked, in: rect)
    }

    private static func drawBackground(_ bg: CGImage, in ctx: CGContext, canvas: CGSize, fit: BgFit) {
        switch fit {
        case .tile:
            drawTiled(bg, in: ctx, canvas: canvas)
        case .cover, .contain, .center:
            ctx.draw(bg, in: fitRect(
                content: CGSize(width: bg.width, height: bg.height),
                canvas: canvas,
                fit: fit
            ))
        }
    }

    private static func drawTiled(_ bg: CGImage, in ctx: CGContext, canvas: CGSize) {
        let tileW = max(CGFloat(bg.width), 1)
        let tileH = max(CGFloat(bg.height), 1)
        var startX = (canvas.width - tileW) / 2
        var startY = (canvas.height - tileH) / 2
        while startX > 0 { startX -= tileW }
        while startY > 0 { startY -= tileH }

        var y = startY
        while y < canvas.height {
            var x = startX
            while x < canvas.width {
                ctx.draw(bg, in: CGRect(x: x, y: y, width: tileW, height: tileH))
                x += tileW
            }
            y += tileH
        }
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
        case .center, .tile:
            return CGRect(
                x: (canvas.width - content.width) / 2,
                y: (canvas.height - content.height) / 2,
                width: content.width,
                height: content.height
            )
        }
    }
}
