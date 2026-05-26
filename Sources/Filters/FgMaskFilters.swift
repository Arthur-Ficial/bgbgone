import Foundation
import CoreImage
import BgBgOneCore

/// Mask-aware foreground-only filters. Each uses the LayeredImage.foregroundMask
/// to derive its effect (outline, glow, shadow, silhouette, cutout, matte,
/// inner-shadow). All reject layers other than `.fg`.

private func parseRGBAColor(_ args: [FilterArg], default def: RGBA, filter: String) throws -> RGBA {
    try FilterArgValue.keyedColor(args, default: def, filter: filter)
}

private func ciColor(_ rgba: RGBA, alpha: CGFloat = 1) -> CIColor {
    CIColor(red: CGFloat(rgba.r), green: CGFloat(rgba.g), blue: CGFloat(rgba.b), alpha: alpha)
}

private func compositeOver(_ top: CIImage, on bottom: CIImage, extent: CGRect) throws -> CIImage {
    guard let f = CIFilter(name: "CISourceOverCompositing") else {
        throw BgBgOneError.frameworkError(ErrorCodes.frameworkVisionFail, "CISourceOverCompositing unavailable")
    }
    f.setValue(top, forKey: kCIInputImageKey)
    f.setValue(bottom, forKey: kCIInputBackgroundImageKey)
    guard let out = f.outputImage?.cropped(to: extent) else {
        throw BgBgOneError.frameworkError(ErrorCodes.frameworkComposeFail, "composite over failed")
    }
    return out
}

private func blendWithMask(_ image: CIImage, background: CIImage, mask: CIImage, extent: CGRect) throws -> CIImage {
    guard let f = CIFilter(name: "CIBlendWithMask") else {
        throw BgBgOneError.frameworkError(ErrorCodes.frameworkVisionFail, "CIBlendWithMask unavailable")
    }
    f.setValue(image, forKey: kCIInputImageKey)
    f.setValue(background, forKey: kCIInputBackgroundImageKey)
    f.setValue(mask, forKey: kCIInputMaskImageKey)
    guard let out = f.outputImage?.cropped(to: extent) else {
        throw BgBgOneError.frameworkError(ErrorCodes.frameworkComposeFail, "blend with mask failed")
    }
    return out
}

/// Render a solid-colour CIImage at the given extent.
private func solidPlane(_ rgba: RGBA, extent: CGRect) throws -> CIImage {
    guard let f = CIFilter(name: "CIConstantColorGenerator") else {
        throw BgBgOneError.frameworkError(ErrorCodes.frameworkVisionFail, "CIConstantColorGenerator unavailable")
    }
    f.setValue(ciColor(rgba), forKey: kCIInputColorKey)
    guard let out = f.outputImage?.cropped(to: extent) else {
        throw BgBgOneError.frameworkError(ErrorCodes.frameworkComposeFail, "solid plane failed")
    }
    return out
}

public enum SilhouetteFilter: Filter {
    public static let name = "silhouette"
    public static let validLayers: Set<FilterLayer> = [.fg]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let color = try parseRGBAColor(args, default: RGBA(r: 0, g: 0, b: 0, a: 1), filter: name)
        let extent = image.foreground.extent
        let plane = try solidPlane(color, extent: extent)
        // Replace fg pixels with solid colour; mask still controls compositing in flatten.
        var r = image; r.foreground = plane; return r
    }
}

public enum CutoutFilter: Filter {
    public static let name = "cutout"
    public static let validLayers: Set<FilterLayer> = [.fg]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        // Invert the mask so the subject becomes a hole; background shows through.
        guard let f = CIFilter(name: "CIColorInvert") else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkVisionFail, "CIColorInvert unavailable")
        }
        f.setValue(image.foregroundMask, forKey: kCIInputImageKey)
        guard let inverted = f.outputImage?.cropped(to: image.foregroundMask.extent) else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkComposeFail, "cutout: invert failed")
        }
        var r = image; r.foregroundMask = inverted; return r
    }
}

public enum MatteFilter: Filter {
    public static let name = "matte"
    public static let validLayers: Set<FilterLayer> = [.fg]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        // Emit the alpha mask itself as the final foreground RGB (grayscale).
        var r = image
        r.foreground = image.foregroundMask
        // Make mask fully opaque so the matte shows through.
        guard let opaque = CIFilter(name: "CIColorMatrix") else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkVisionFail, "CIColorMatrix unavailable")
        }
        opaque.setValue(image.foregroundMask, forKey: kCIInputImageKey)
        opaque.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        opaque.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBiasVector")
        if let out = opaque.outputImage?.cropped(to: image.foregroundMask.extent) {
            r.foregroundMask = out
        }
        return r
    }
}

public enum OutlineFilter: Filter {
    public static let name = "outline"
    public static let validLayers: Set<FilterLayer> = [.fg]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let width = try FilterArgValue.keyedNumber(args, key: "width", default: 3.0, filter: name)
        let color = try parseRGBAColor(args, default: RGBA(r: 1, g: 1, b: 1, a: 1), filter: name)
        let extent = image.foreground.extent
        // Dilate mask by `width` pixels, subtract original mask -> ring shape.
        guard let dilate = CIFilter(name: "CIMorphologyMaximum") else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkVisionFail, "CIMorphologyMaximum unavailable")
        }
        dilate.setValue(image.foregroundMask, forKey: kCIInputImageKey)
        dilate.setValue(width, forKey: kCIInputRadiusKey)
        guard let dilated = dilate.outputImage?.cropped(to: extent) else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkComposeFail, "outline: dilate failed")
        }
        // ring = dilated - original mask (subtract via CISubtractBlendMode)
        guard let sub = CIFilter(name: "CISubtractBlendMode") else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkVisionFail, "CISubtractBlendMode unavailable")
        }
        sub.setValue(dilated, forKey: kCIInputImageKey)
        sub.setValue(image.foregroundMask, forKey: kCIInputBackgroundImageKey)
        guard let ring = sub.outputImage?.cropped(to: extent) else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkComposeFail, "outline: ring failed")
        }
        // Construct a new foreground: subject pixels where original mask=1,
        // ring colour where original mask=0 but dilated mask=1. The flatten
        // step uses dilated mask, so anywhere outside the dilated region the
        // bg plate still shows through.
        let ringPlane = try solidPlane(color, extent: extent)
        var r = image
        r.foreground = try blendWithMask(image.foreground, background: ringPlane, mask: image.foregroundMask, extent: extent)
        r.foregroundMask = dilated
        // Mark _ used to silence unused warning on `ring` while keeping the
        // diagnostic-friendly intermediate around for clarity.
        _ = ring
        return r
    }
}

public enum GlowFilter: Filter {
    public static let name = "glow"
    public static let validLayers: Set<FilterLayer> = [.fg]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let radius = try FilterArgValue.keyedNumber(args, key: "radius", default: 10.0, filter: name)
        let intensity = try FilterArgValue.keyedNumber(args, key: "intensity", default: 0.5, filter: name)
        let color = try parseRGBAColor(args, default: RGBA(r: 1, g: 1, b: 0.5, a: 1), filter: name)
        let extent = image.foreground.extent
        guard let blur = CIFilter(name: "CIGaussianBlur") else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkCIBlurUnavailable, "CIGaussianBlur unavailable")
        }
        blur.setValue(image.foregroundMask, forKey: kCIInputImageKey)
        blur.setValue(radius, forKey: kCIInputRadiusKey)
        guard let blurred = blur.outputImage?.cropped(to: extent) else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkCIBlurNoOutput, "glow: blur failed")
        }
        // Construct foreground: subject pixels where original_mask=1, glow colour
        // (alpha=intensity * blurredMaskValue) where original_mask=0. Output mask
        // = blurred so the flatten step shows subject + halo, bg plate shows
        // elsewhere.
        let glowPlane = try solidPlane(color, extent: extent)
        // Scale plane alpha by intensity so the glow is tunable.
        guard let alpha = CIFilter(name: "CIColorMatrix") else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkVisionFail, "CIColorMatrix unavailable")
        }
        alpha.setValue(glowPlane, forKey: kCIInputImageKey)
        alpha.setValue(CIVector(x: 0, y: 0, z: 0, w: CGFloat(intensity)), forKey: "inputAVector")
        guard let tunedPlane = alpha.outputImage?.cropped(to: extent) else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkComposeFail, "glow: alpha tune failed")
        }
        var r = image
        r.foreground = try blendWithMask(image.foreground, background: tunedPlane, mask: image.foregroundMask, extent: extent)
        r.foregroundMask = blurred
        return r
    }
}

public enum ShadowFilter: Filter {
    public static let name = "shadow"
    public static let validLayers: Set<FilterLayer> = [.fg]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let blur = try FilterArgValue.keyedNumber(args, key: "blur", default: 12.0, filter: name)
        let (dx, dy) = try FilterArgValue.keyedPoint(args, key: "offset", default: (0.0, 0.0), filter: name)
        let opacity = try FilterArgValue.keyedNumber(args, key: "opacity", default: 0.5, filter: name)
        let color = try parseRGBAColor(args, default: RGBA(r: 0, g: 0, b: 0, a: 1), filter: name)
        let extent = image.foreground.extent
        // Translate the mask by (dx, dy), then blur, then tint.
        let translated = image.foregroundMask.transformed(by: CGAffineTransform(translationX: dx, y: -dy))
        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkCIBlurUnavailable, "CIGaussianBlur unavailable")
        }
        blurFilter.setValue(translated, forKey: kCIInputImageKey)
        blurFilter.setValue(blur, forKey: kCIInputRadiusKey)
        guard let shadowMask = blurFilter.outputImage?.cropped(to: extent) else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkCIBlurNoOutput, "shadow: blur failed")
        }
        // Compose union of original mask + translated/blurred shadow mask so
        // the flatten step keeps both subject and shadow visible.
        guard let union = CIFilter(name: "CIMaximumCompositing") else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkVisionFail, "CIMaximumCompositing unavailable")
        }
        union.setValue(image.foregroundMask, forKey: kCIInputImageKey)
        union.setValue(shadowMask, forKey: kCIInputBackgroundImageKey)
        guard let unionMask = union.outputImage?.cropped(to: extent) else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkComposeFail, "shadow: union mask failed")
        }
        // Tune shadow plane alpha by opacity * blurred mask value.
        let shadowPlane = try solidPlane(color, extent: extent)
        guard let alpha = CIFilter(name: "CIColorMatrix") else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkVisionFail, "CIColorMatrix unavailable")
        }
        alpha.setValue(shadowPlane, forKey: kCIInputImageKey)
        alpha.setValue(CIVector(x: 0, y: 0, z: 0, w: CGFloat(opacity)), forKey: "inputAVector")
        guard let tunedShadow = alpha.outputImage?.cropped(to: extent) else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkComposeFail, "shadow: alpha tune failed")
        }
        // Foreground = subject where original mask=1, tuned shadow where mask=0.
        var r = image
        r.foreground = try blendWithMask(image.foreground, background: tunedShadow, mask: image.foregroundMask, extent: extent)
        r.foregroundMask = unionMask
        return r
    }
}

public enum InnerShadowFilter: Filter {
    public static let name = "inner-shadow"
    public static let validLayers: Set<FilterLayer> = [.fg]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let blur = try FilterArgValue.keyedNumber(args, key: "blur", default: 6.0, filter: name)
        let (dx, dy) = try FilterArgValue.keyedPoint(args, key: "offset", default: (0.0, 0.0), filter: name)
        let opacity = try FilterArgValue.keyedNumber(args, key: "opacity", default: 0.5, filter: name)
        let color = try parseRGBAColor(args, default: RGBA(r: 0, g: 0, b: 0, a: 1), filter: name)
        let extent = image.foreground.extent
        guard let invert = CIFilter(name: "CIColorInvert") else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkVisionFail, "CIColorInvert unavailable")
        }
        invert.setValue(image.foregroundMask, forKey: kCIInputImageKey)
        guard let inverted = invert.outputImage?.cropped(to: extent) else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkComposeFail, "inner-shadow: invert failed")
        }
        let translated = inverted.transformed(by: CGAffineTransform(translationX: dx, y: -dy))
        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkCIBlurUnavailable, "CIGaussianBlur unavailable")
        }
        blurFilter.setValue(translated, forKey: kCIInputImageKey)
        blurFilter.setValue(blur, forKey: kCIInputRadiusKey)
        guard let shadowMask = blurFilter.outputImage?.cropped(to: extent) else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkCIBlurNoOutput, "inner-shadow: blur failed")
        }
        // Intersect with original mask so the shadow stays inside the subject.
        guard let mult = CIFilter(name: "CIMultiplyCompositing") else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkVisionFail, "CIMultiplyCompositing unavailable")
        }
        mult.setValue(shadowMask, forKey: kCIInputImageKey)
        mult.setValue(image.foregroundMask, forKey: kCIInputBackgroundImageKey)
        guard let intersected = mult.outputImage?.cropped(to: extent) else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkComposeFail, "inner-shadow: intersect failed")
        }
        let plane = try solidPlane(color, extent: extent)
        let tinted = try blendWithMask(plane, background: image.foreground, mask: intersected, extent: extent)
        guard let alpha = CIFilter(name: "CIColorMatrix") else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkVisionFail, "CIColorMatrix unavailable")
        }
        alpha.setValue(tinted, forKey: kCIInputImageKey)
        alpha.setValue(CIVector(x: 0, y: 0, z: 0, w: CGFloat(opacity)), forKey: "inputAVector")
        guard let inner = alpha.outputImage?.cropped(to: extent) else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkComposeFail, "inner-shadow: alpha tune failed")
        }
        var r = image
        r.foreground = try compositeOver(inner, on: image.foreground, extent: extent)
        return r
    }
}
