import Foundation
import CoreImage
import BgBgOneCore

/// Shared infrastructure for pixel filters that wrap a single CIFilter
/// applied to fg/bg/all layers. The mask layer is rejected at the
/// per-filter level (these filters operate on RGB, not the mask).
public enum PixelFilterHelper {
    public static func applyCI(
        name ciName: String,
        params: [String: Any],
        to layered: LayeredImage,
        on layer: FilterLayer,
        humanName: String,
        forceOpaque: Bool = false
    ) throws -> LayeredImage {
        var out = layered
        switch layer {
        case .fg:
            out.foreground = try transform(layered.foreground, ciName: ciName, params: params, humanName: humanName, forceOpaque: forceOpaque)
        case .bg:
            out.background = try transform(layered.background, ciName: ciName, params: params, humanName: humanName, forceOpaque: forceOpaque)
        case .all:
            out.foreground = try transform(layered.foreground, ciName: ciName, params: params, humanName: humanName, forceOpaque: forceOpaque)
            out.background = try transform(layered.background, ciName: ciName, params: params, humanName: humanName, forceOpaque: forceOpaque)
        case .mask:
            throw rejectMask(humanName)
        case .composite:
            throw BgBgOneError.parser(
                ErrorCodes.parseFlagValueInvalid,
                "filter \(humanName) does not accept layer composite",
                origin: "--filter",
                context: ["name": humanName, "layer": "composite"]
            )
        }
        return out
    }

    public static func applyCIToImage(
        name ciName: String,
        params: [String: Any],
        image: CIImage,
        humanName: String,
        forceOpaque: Bool = false
    ) throws -> CIImage {
        try transform(image, ciName: ciName, params: params, humanName: humanName, forceOpaque: forceOpaque)
    }

    private static func transform(_ image: CIImage, ciName: String, params: [String: Any], humanName: String, forceOpaque: Bool) throws -> CIImage {
        guard let filter = CIFilter(name: ciName) else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkVisionFail, "\(ciName) unavailable (filter \(humanName))")
        }
        filter.setValue(image, forKey: kCIInputImageKey)
        for (k, v) in params { filter.setValue(v, forKey: k) }
        guard let out = filter.outputImage else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkComposeFail, "\(humanName): no output from \(ciName)")
        }
        let cropped = out.cropped(to: image.extent)
        return forceOpaque ? try opaque(cropped, humanName: humanName) : cropped
    }

    private static func opaque(_ image: CIImage, humanName: String) throws -> CIImage {
        guard let filter = CIFilter(name: "CIColorMatrix") else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkVisionFail, "CIColorMatrix unavailable (filter \(humanName))")
        }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputAVector")
        filter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputBiasVector")
        guard let out = filter.outputImage else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkComposeFail, "\(humanName): cannot make output opaque")
        }
        return out.cropped(to: image.extent)
    }

    public static func rejectMask(_ humanName: String) -> BgBgOneError {
        BgBgOneError.parser(
            ErrorCodes.parseFlagValueInvalid,
            "filter \(humanName) does not accept layer mask",
            origin: "--filter",
            context: ["name": humanName, "layer": "mask"]
        )
    }

    /// Extract a single named or positional float arg, with default.
    public static func floatArg(_ args: [FilterArg], key: String? = nil, default def: Double) throws -> Double {
        for a in args {
            switch a {
            case .keyed(let k, let v) where k.lowercased() == key?.lowercased():
                guard let d = Double(v) else { throw badArg(value: v, name: k) }
                return d
            case .value(let v) where key == nil:
                guard let d = Double(v) else { throw badArg(value: v, name: "value") }
                return d
            default: continue
            }
        }
        if key == nil, args.count == 1, case .keyed(let k, let v) = args[0] {
            guard let d = Double(v) else { throw badArg(value: v, name: k) }
            return d
        }
        return def
    }

    public static func requireRange(_ value: Double, _ range: ClosedRange<Double>, name: String, filter: String) throws -> Double {
        guard range.contains(value) else {
            throw BgBgOneError.parser(
                ErrorCodes.parseFlagValueInvalid,
                "filter \(filter): \(name) must be \(range.lowerBound)..\(range.upperBound), got \(value)",
                origin: "--filter",
                context: ["filter": filter, "arg": name, "value": String(value)]
            )
        }
        return value
    }

    private static func badArg(value: String, name: String) -> BgBgOneError {
        BgBgOneError.parser(
            ErrorCodes.parseFlagValueInvalid,
            "filter arg \(name)=\(value) is not a number",
            origin: "--filter",
            context: ["arg": name, "value": value]
        )
    }
}

// MARK: - Trivial single-CIFilter wraps. One per filter ticket.

public enum DesaturateFilter: Filter {
    public static let name = "desaturate"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let amount = try PixelFilterHelper.requireRange(
            PixelFilterHelper.floatArg(args, default: 1.0),
            0.0...1.0,
            name: "amount",
            filter: name
        )
        let saturation = 1.0 - amount
        return try PixelFilterHelper.applyCI(name: "CIColorControls", params: ["inputSaturation": saturation], to: image, on: layer, humanName: name)
    }
}

public enum NegateFilter: Filter {
    public static let name = "negate"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        try PixelFilterHelper.applyCI(name: "CIColorInvert", params: [:], to: image, on: layer, humanName: name)
    }
}

public enum SepiaFilter: Filter {
    public static let name = "sepia"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let intensity = try PixelFilterHelper.floatArg(args, default: 1.0)
        return try PixelFilterHelper.applyCI(name: "CISepiaTone", params: ["inputIntensity": intensity], to: image, on: layer, humanName: name)
    }
}

public enum GammaFilter: Filter {
    public static let name = "gamma"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let value = try PixelFilterHelper.floatArg(args, default: 1.0)
        return try PixelFilterHelper.applyCI(name: "CIGammaAdjust", params: ["inputPower": value], to: image, on: layer, humanName: name)
    }
}

public enum ExposureFilter: Filter {
    public static let name = "exposure"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let stops = try PixelFilterHelper.floatArg(args, default: 0.0)
        return try PixelFilterHelper.applyCI(name: "CIExposureAdjust", params: ["inputEV": stops], to: image, on: layer, humanName: name)
    }
}

public enum HueFilter: Filter {
    public static let name = "hue"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let degrees = try PixelFilterHelper.floatArg(args, default: 0.0)
        let radians = degrees * .pi / 180.0
        return try PixelFilterHelper.applyCI(name: "CIHueAdjust", params: ["inputAngle": radians], to: image, on: layer, humanName: name)
    }
}

public enum VibranceFilter: Filter {
    public static let name = "vibrance"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let amount = try PixelFilterHelper.floatArg(args, default: 0.0)
        return try PixelFilterHelper.applyCI(name: "CIVibrance", params: ["inputAmount": amount], to: image, on: layer, humanName: name)
    }
}

public enum BlurFilter: Filter {
    public static let name = "blur"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let radius = try PixelFilterHelper.floatArg(args, default: 10.0)
        return try PixelFilterHelper.applyCI(name: "CIGaussianBlur", params: ["inputRadius": radius], to: image, on: layer, humanName: name)
    }
}

public enum BoxBlurFilter: Filter {
    public static let name = "box-blur"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let radius = try PixelFilterHelper.floatArg(args, default: 10.0)
        return try PixelFilterHelper.applyCI(name: "CIBoxBlur", params: ["inputRadius": radius], to: image, on: layer, humanName: name)
    }
}

public enum SharpenFilter: Filter {
    public static let name = "sharpen"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let amount = try PixelFilterHelper.floatArg(args, default: 0.4)
        return try PixelFilterHelper.applyCI(name: "CISharpenLuminance", params: ["inputSharpness": amount], to: image, on: layer, humanName: name)
    }
}

public enum PosterizeFilter: Filter {
    public static let name = "posterize"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let levels = try PixelFilterHelper.floatArg(args, default: 6.0)
        return try PixelFilterHelper.applyCI(name: "CIColorPosterize", params: ["inputLevels": levels], to: image, on: layer, humanName: name)
    }
}

public enum EdgesFilter: Filter {
    public static let name = "edges"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let intensity = try PixelFilterHelper.floatArg(args, default: 1.0)
        return try PixelFilterHelper.applyCI(name: "CIEdges", params: ["inputIntensity": intensity], to: image, on: layer, humanName: name)
    }
}

public enum ComicFilter: Filter {
    public static let name = "comic"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        try PixelFilterHelper.applyCI(name: "CIComicEffect", params: [:], to: image, on: layer, humanName: name)
    }
}

public enum AdjustFilter: Filter {
    public static let name = "adjust"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let params: [String: Any] = [
            "inputBrightness": try FilterArgValue.keyedNumber(args, key: "brightness", default: 0.0, filter: name),
            "inputContrast": try FilterArgValue.keyedNumber(args, key: "contrast", default: 1.0, filter: name),
            "inputSaturation": try FilterArgValue.keyedNumber(args, key: "saturation", default: 1.0, filter: name),
        ]
        return try PixelFilterHelper.applyCI(name: "CIColorControls", params: params, to: image, on: layer, humanName: name)
    }
}
