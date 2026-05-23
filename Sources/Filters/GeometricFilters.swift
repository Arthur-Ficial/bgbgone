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
        var dx = 0.0, dy = 0.0
        for a in args {
            if case .value(let v) = a {
                let parts = v.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
                if parts.count == 2 { dx = parts[0]; dy = parts[1] }
            }
        }
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
        var axis = "horizontal"
        for a in args {
            if case .value(let v) = a { axis = v.lowercased() }
        }
        let t: CGAffineTransform
        switch axis {
        case "horizontal": t = CGAffineTransform(scaleX: -1, y: 1)
        case "vertical":   t = CGAffineTransform(scaleX: 1, y: -1)
        default:
            throw BgBgOneError.parser(
                ErrorCodes.parseFlagValueInvalid,
                "filter flip: axis must be horizontal or vertical, got \(axis)",
                origin: "--filter",
                context: ["axis": axis]
            )
        }
        return applyAffine(image, t)
    }
}
