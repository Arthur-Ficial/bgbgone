import Foundation
import CoreImage
import BgBgOneCore

// MARK: composite-only (vignette family) — operate on the final composite via `all` layer.

public enum VignetteFilter: Filter {
    public static let name = "vignette"
    public static let validLayers: Set<FilterLayer> = [.all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        var intensity = 1.0, radius = 1.0
        var positional = 0
        for a in args {
            switch a {
            case .keyed(let k, let v):
                if let d = Double(v) {
                    switch k.lowercased() {
                    case "intensity": intensity = d
                    case "radius":    radius    = d
                    default: break
                    }
                }
            case .value(let v):
                if let d = Double(v) {
                    if positional == 0 { intensity = d } else if positional == 1 { radius = d }
                    positional += 1
                }
            }
        }
        return try PixelFilterHelper.applyCI(name: "CIVignette", params: ["inputIntensity": intensity, "inputRadius": radius], to: image, on: layer, humanName: name)
    }
}

public enum VignetteEffectFilter: Filter {
    public static let name = "vignette-effect"
    public static let validLayers: Set<FilterLayer> = [.all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        var cx = 0.5, cy = 0.5, radius = 1.5, intensity = 1.0
        for a in args {
            if case .keyed(let k, let v) = a {
                switch k.lowercased() {
                case "center":
                    let parts = v.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
                    if parts.count == 2 { cx = parts[0]; cy = parts[1] }
                case "radius":
                    if let d = Double(v) { radius = d }
                case "intensity":
                    if let d = Double(v) { intensity = d }
                default: break
                }
            }
        }
        let target = image.foreground.extent
        let center = CIVector(x: target.width * cx, y: target.height * (1 - cy))
        return try PixelFilterHelper.applyCI(name: "CIVignetteEffect", params: ["inputCenter": center, "inputRadius": radius * Double(target.width) / 2, "inputIntensity": intensity], to: image, on: layer, humanName: name)
    }
}

public enum BloomFilter: Filter {
    public static let name = "bloom"
    public static let validLayers: Set<FilterLayer> = [.all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        var intensity = 0.5, radius = 10.0
        var positional = 0
        for a in args {
            switch a {
            case .keyed(let k, let v):
                if let d = Double(v) {
                    switch k.lowercased() {
                    case "intensity": intensity = d
                    case "radius":    radius    = d
                    default: break
                    }
                }
            case .value(let v):
                if let d = Double(v) {
                    if positional == 0 { intensity = d } else if positional == 1 { radius = d }
                    positional += 1
                }
            }
        }
        return try PixelFilterHelper.applyCI(name: "CIBloom", params: ["inputIntensity": intensity, "inputRadius": radius], to: image, on: layer, humanName: name)
    }
}

public enum GloomFilter: Filter {
    public static let name = "gloom"
    public static let validLayers: Set<FilterLayer> = [.all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        var intensity = 0.5, radius = 10.0
        var positional = 0
        for a in args {
            switch a {
            case .keyed(let k, let v):
                if let d = Double(v) {
                    switch k.lowercased() {
                    case "intensity": intensity = d
                    case "radius":    radius    = d
                    default: break
                    }
                }
            case .value(let v):
                if let d = Double(v) {
                    if positional == 0 { intensity = d } else if positional == 1 { radius = d }
                    positional += 1
                }
            }
        }
        return try PixelFilterHelper.applyCI(name: "CIGloom", params: ["inputIntensity": intensity, "inputRadius": radius], to: image, on: layer, humanName: name)
    }
}

// MARK: emboss (convolution kernel)

public enum EmbossFilter: Filter {
    public static let name = "emboss"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        // 3x3 emboss kernel: -2 -1 0 / -1 1 1 / 0 1 2 (classic photo emboss).
        let weights = CIVector(values: [-2, -1, 0, -1, 1, 1, 0, 1, 2], count: 9)
        return try PixelFilterHelper.applyCI(name: "CIConvolution3X3", params: ["inputWeights": weights, "inputBias": 0.5], to: image, on: layer, humanName: name)
    }
}

// MARK: noise (additive)

public enum NoiseFilter: Filter {
    public static let name = "noise"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let amount = max(0, min(1, try PixelFilterHelper.floatArg(args, default: 0.2)))
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
        case .fg, .all:
            composite.setValue(grain, forKey: kCIInputImageKey)
            composite.setValue(out.foreground, forKey: kCIInputBackgroundImageKey)
            if let r = composite.outputImage { out.foreground = r.cropped(to: extent) }
            fallthrough
        case .bg:
            composite.setValue(grain, forKey: kCIInputImageKey)
            composite.setValue(out.background, forKey: kCIInputBackgroundImageKey)
            if let r = composite.outputImage { out.background = r.cropped(to: extent) }
        case .mask:
            throw PixelFilterHelper.rejectMask(name)
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
        let t = max(0, min(1, try PixelFilterHelper.floatArg(args, default: 0.5)))
        // CIColorThreshold (macOS 14+) is the natural primitive.
        if let f = CIFilter(name: "CIColorThreshold") {
            f.setValue(image.foregroundMask, forKey: kCIInputImageKey)
            f.setValue(t, forKey: "inputThreshold")
            if let out = f.outputImage?.cropped(to: image.foregroundMask.extent) {
                var r = image; r.foregroundMask = out; return r
            }
        }
        // Fallback: piecewise via CIColorMatrix with steep clamp.
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
