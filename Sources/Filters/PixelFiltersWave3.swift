import Foundation
import CoreImage
import BgBgOneCore

// MARK: composite-only (vignette family) — operate on the final composite via `composite` layer.

private func compositeBase(_ image: LayeredImage, filter: String) throws -> CIImage {
    guard let composite = image.composite else {
        throw BgBgOneError.frameworkError(
            ErrorCodes.frameworkInternalInvariant,
            "filter \(filter) expected a flattened composite image"
        )
    }
    return composite
}

private func applyCompositeCI(
    _ ciName: String,
    params: [String: Any],
    to image: LayeredImage,
    filter: String
) throws -> LayeredImage {
    var out = image
    out.composite = try PixelFilterHelper.applyCIToImage(
        name: ciName,
        params: params,
        image: try compositeBase(image, filter: filter),
        humanName: filter
    )
    return out
}

public enum VignetteFilter: Filter {
    public static let name = "vignette"
    public static let validLayers: Set<FilterLayer> = [.composite]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let positional = try FilterArgValue.positionalNumbers(args, defaults: [1.0, 1.0], filter: name)
        let intensity = try FilterArgValue.keyedNumber(args, key: "intensity", default: positional[0], filter: name)
        let radius = try FilterArgValue.keyedNumber(args, key: "radius", default: positional[1], filter: name)
        return try applyCompositeCI("CIVignette", params: ["inputIntensity": intensity, "inputRadius": radius], to: image, filter: name)
    }
}

public enum VignetteEffectFilter: Filter {
    public static let name = "vignette-effect"
    public static let validLayers: Set<FilterLayer> = [.composite]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let (cx, cy) = try FilterArgValue.keyedPoint(args, key: "center", default: (0.5, 0.5), filter: name)
        let radius = try FilterArgValue.keyedNumber(args, key: "radius", default: 1.5, filter: name)
        let intensity = try FilterArgValue.keyedNumber(args, key: "intensity", default: 1.0, filter: name)
        let target = try compositeBase(image, filter: name).extent
        let center = CIVector(x: target.width * cx, y: target.height * (1 - cy))
        var out = image
        out.composite = try PixelFilterHelper.applyCIToImage(
            name: "CIVignetteEffect",
            params: ["inputCenter": center, "inputRadius": radius * Double(target.width) / 2, "inputIntensity": intensity],
            image: try compositeBase(image, filter: name),
            humanName: name
        )
        return out
    }
}

public enum BloomFilter: Filter {
    public static let name = "bloom"
    public static let validLayers: Set<FilterLayer> = [.composite]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let positional = try FilterArgValue.positionalNumbers(args, defaults: [0.5, 10.0], filter: name)
        let intensity = try FilterArgValue.keyedNumber(args, key: "intensity", default: positional[0], filter: name)
        let radius = try FilterArgValue.keyedNumber(args, key: "radius", default: positional[1], filter: name)
        return try applyCompositeCI("CIBloom", params: ["inputIntensity": intensity, "inputRadius": radius], to: image, filter: name)
    }
}

public enum GloomFilter: Filter {
    public static let name = "gloom"
    public static let validLayers: Set<FilterLayer> = [.composite]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let positional = try FilterArgValue.positionalNumbers(args, defaults: [0.5, 10.0], filter: name)
        let intensity = try FilterArgValue.keyedNumber(args, key: "intensity", default: positional[0], filter: name)
        let radius = try FilterArgValue.keyedNumber(args, key: "radius", default: positional[1], filter: name)
        return try applyCompositeCI("CIGloom", params: ["inputIntensity": intensity, "inputRadius": radius], to: image, filter: name)
    }
}

// MARK: emboss (convolution kernel)

public enum EmbossFilter: Filter {
    public static let name = "emboss"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        // Zero-sum emboss kernel with 0.5 bias keeps relief centered around gray.
        let weights = CIVector(values: [-2, -1, 0, -1, 0, 1, 0, 1, 2], count: 9)
        let relief = try PixelFilterHelper.applyCI(
            name: "CIConvolution3X3",
            params: ["inputWeights": weights, "inputBias": 0.5],
            to: image,
            on: layer,
            humanName: name,
            forceOpaque: true
        )
        return try PixelFilterHelper.applyCI(
            name: "CIColorControls",
            params: ["inputSaturation": 0.0, "inputContrast": 2.0, "inputBrightness": -0.85],
            to: relief,
            on: layer,
            humanName: name
        )
    }
}

// MARK: noise (additive)

public enum NoiseFilter: Filter {
    public static let name = "noise"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let amount = try PixelFilterHelper.requireRange(
            PixelFilterHelper.floatArg(args, default: 0.2),
            0.0...1.0,
            name: "amount",
            filter: name
        )
        guard let randomFilter = CIFilter(name: "CIRandomGenerator"),
              let random = randomFilter.outputImage else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkVisionFail, "CIRandomGenerator unavailable")
        }
        // Convert random RGB noise to grayscale and crop to the foreground extent.
        guard let mono = CIFilter(name: "CIColorMonochrome") else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkVisionFail, "CIColorMonochrome unavailable")
        }
        mono.setValue(random, forKey: kCIInputImageKey)
        mono.setValue(CIColor(red: 0.5, green: 0.5, blue: 0.5), forKey: "inputColor")
        mono.setValue(1.0, forKey: "inputIntensity")
        let extent = image.foreground.extent
        guard var grain = mono.outputImage?.cropped(to: extent) else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkComposeFail, "noise: grain compose failed")
        }
        // Scale alpha by amount so the noise blends gently.
        if let alpha = CIFilter(name: "CIColorMatrix") {
            alpha.setValue(grain, forKey: kCIInputImageKey)
            alpha.setValue(CIVector(x: 0, y: 0, z: 0, w: CGFloat(amount)), forKey: "inputAVector")
            if let out = alpha.outputImage { grain = out }
        }
        guard let composite = CIFilter(name: "CISourceOverCompositing") else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkVisionFail, "CISourceOverCompositing unavailable")
        }
        var out = image
        switch layer {
        case .fg:
            composite.setValue(grain, forKey: kCIInputImageKey)
            composite.setValue(out.foreground, forKey: kCIInputBackgroundImageKey)
            if let r = composite.outputImage { out.foreground = r.cropped(to: extent) }
        case .bg:
            composite.setValue(grain, forKey: kCIInputImageKey)
            composite.setValue(out.background, forKey: kCIInputBackgroundImageKey)
            if let r = composite.outputImage { out.background = r.cropped(to: extent) }
        case .all:
            composite.setValue(grain, forKey: kCIInputImageKey)
            composite.setValue(out.foreground, forKey: kCIInputBackgroundImageKey)
            if let r = composite.outputImage { out.foreground = r.cropped(to: extent) }
            composite.setValue(grain, forKey: kCIInputImageKey)
            composite.setValue(out.background, forKey: kCIInputBackgroundImageKey)
            if let r = composite.outputImage { out.background = r.cropped(to: extent) }
        case .mask:
            throw PixelFilterHelper.rejectMask(name)
        case .composite:
            throw BgBgOneError.parser(
                ErrorCodes.parseFlagValueInvalid,
                "filter noise does not accept layer composite",
                origin: "--filter",
                context: ["name": name, "layer": "composite"]
            )
        }
        return out
    }
}

// MARK: mask-shape (operate on the foreground mask channel)

public enum FeatherFilter: Filter {
    public static let name = "feather"
    public static let validLayers: Set<FilterLayer> = [.mask]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let radius = try PixelFilterHelper.floatArg(args, default: 4.0)
        guard let blur = CIFilter(name: "CIGaussianBlur") else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkCIBlurUnavailable, "CIGaussianBlur unavailable")
        }
        blur.setValue(image.foregroundMask, forKey: kCIInputImageKey)
        blur.setValue(radius, forKey: kCIInputRadiusKey)
        guard let out = blur.outputImage?.cropped(to: image.foregroundMask.extent) else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkCIBlurNoOutput, "feather: no output")
        }
        var r = image; r.foregroundMask = out; return r
    }
}

public enum ThresholdFilter: Filter {
    public static let name = "threshold"
    public static let validLayers: Set<FilterLayer> = [.mask]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let t = try PixelFilterHelper.requireRange(
            PixelFilterHelper.floatArg(args, default: 0.5),
            0.0...1.0,
            name: "value",
            filter: name
        )
        // CIColorThreshold (macOS 14+) is the natural primitive.
        if let f = CIFilter(name: "CIColorThreshold") {
            f.setValue(image.foregroundMask, forKey: kCIInputImageKey)
            f.setValue(t, forKey: "inputThreshold")
            if let out = f.outputImage?.cropped(to: image.foregroundMask.extent) {
                var r = image; r.foregroundMask = out; return r
            }
        }
        throw BgBgOneError.frameworkError(ErrorCodes.frameworkVisionFail, "CIColorThreshold unavailable on this macOS")
    }
}

public enum ExpandFilter: Filter {
    public static let name = "expand"
    public static let validLayers: Set<FilterLayer> = [.mask]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let pixels = try PixelFilterHelper.floatArg(args, default: 1.0)
        guard let f = CIFilter(name: "CIMorphologyMaximum") else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkVisionFail, "CIMorphologyMaximum unavailable")
        }
        f.setValue(image.foregroundMask, forKey: kCIInputImageKey)
        f.setValue(pixels, forKey: kCIInputRadiusKey)
        guard let out = f.outputImage?.cropped(to: image.foregroundMask.extent) else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkComposeFail, "expand: no output")
        }
        var r = image; r.foregroundMask = out; return r
    }
}

public enum ContractFilter: Filter {
    public static let name = "contract"
    public static let validLayers: Set<FilterLayer> = [.mask]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let pixels = try PixelFilterHelper.floatArg(args, default: 1.0)
        guard let f = CIFilter(name: "CIMorphologyMinimum") else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkVisionFail, "CIMorphologyMinimum unavailable")
        }
        f.setValue(image.foregroundMask, forKey: kCIInputImageKey)
        f.setValue(pixels, forKey: kCIInputRadiusKey)
        guard let out = f.outputImage?.cropped(to: image.foregroundMask.extent) else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkComposeFail, "contract: no output")
        }
        var r = image; r.foregroundMask = out; return r
    }
}
