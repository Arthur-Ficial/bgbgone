import Foundation
import CoreImage
import BgBgOneCore

/// Geometric foreground-only filters: scale, translate, rotate, flip.
/// Apply the same affine transform to both `foreground` and `foregroundMask`
/// so the matte stays aligned with the subject pixels.

private func applyAffine(_ image: LayeredImage, _ transform: CGAffineTransform) -> LayeredImage {
    var r = image
    let extent = image.foreground.extent
    let centered = transform.concatenating(.identity)
    let _ = centered
    // Translate so transform pivots around the image centre.
    let toOrigin = CGAffineTransform(translationX: -extent.midX, y: -extent.midY)
    let toCenter = CGAffineTransform(translationX: extent.midX, y: extent.midY)
    let pivoted = toOrigin.concatenating(transform).concatenating(toCenter)
    r.foreground = image.foreground.transformed(by: pivoted).cropped(to: extent)
    r.foregroundMask = image.foregroundMask.transformed(by: pivoted).cropped(to: extent)
    return r
}

public enum ScaleFilter: Filter {
    public static let name = "scale"
    public static let validLayers: Set<FilterLayer> = [.fg]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let factor = try PixelFilterHelper.floatArg(args, default: 1.0)
        return applyAffine(image, CGAffineTransform(scaleX: factor, y: factor))
    }
}

public enum TranslateFilter: Filter {
    public static let name = "translate"
    public static let validLayers: Set<FilterLayer> = [.fg]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let (dx, dy) = try FilterArgValue.firstPoint(args, default: (0.0, 0.0), filter: name)
        // Apply translation without the centre-pivot (translation has no fixed point).
        var r = image
        let extent = image.foreground.extent
        let t = CGAffineTransform(translationX: dx, y: -dy)
        r.foreground = image.foreground.transformed(by: t).cropped(to: extent)
        r.foregroundMask = image.foregroundMask.transformed(by: t).cropped(to: extent)
        return r
    }
}

public enum RotateFilter: Filter {
    public static let name = "rotate"
    public static let validLayers: Set<FilterLayer> = [.fg]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let degrees = try PixelFilterHelper.floatArg(args, default: 0.0)
        let radians = degrees * .pi / 180.0
        return applyAffine(image, CGAffineTransform(rotationAngle: -radians))
    }
}

public enum FlipFilter: Filter {
    public static let name = "flip"
    public static let validLayers: Set<FilterLayer> = [.fg]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let axis = try FilterArgValue.choice(args, default: "horizontal", choices: ["horizontal", "vertical"], filter: name)
        let t: CGAffineTransform
        switch axis {
        case "horizontal": t = CGAffineTransform(scaleX: -1, y: 1)
        case "vertical":   t = CGAffineTransform(scaleX: 1, y: -1)
        default:
            throw BgBgOneError.frameworkError(
                ErrorCodes.frameworkInternalInvariant,
                "validated flip axis escaped FilterArgValue.choice"
            )
        }
        return applyAffine(image, t)
    }
}
