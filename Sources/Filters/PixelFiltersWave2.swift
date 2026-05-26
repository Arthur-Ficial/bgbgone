import Foundation
import CoreImage
import BgBgOneCore

/// Wave 2 of the pixel-filter catalogue. More single- or few-CIFilter wraps
/// covering colour-pair, blur variants, and stylise.

public enum TemperatureFilter: Filter {
    public static let name = "temperature"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let k = try PixelFilterHelper.floatArg(args, default: 6500)
        // CITemperatureAndTint expects 2D vectors. Target = chosen K; neutral = 6500K.
        let target = CIVector(x: CGFloat(k), y: 0)
        let neutral = CIVector(x: 6500, y: 0)
        return try PixelFilterHelper.applyCI(name: "CITemperatureAndTint", params: ["inputTargetNeutral": target, "inputNeutral": neutral], to: image, on: layer, humanName: name)
    }
}

public enum MotionBlurFilter: Filter {
    public static let name = "motion-blur"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let positional = try FilterArgValue.positionalNumbers(args, defaults: [20.0, 0.0], filter: name)
        let radius = try FilterArgValue.keyedNumber(args, key: "radius", default: positional[0], filter: name)
        let angle = try FilterArgValue.keyedNumber(args, key: "angle", default: positional[1], filter: name) * .pi / 180
        return try PixelFilterHelper.applyCI(name: "CIMotionBlur", params: ["inputRadius": radius, "inputAngle": angle], to: image, on: layer, humanName: name)
    }
}

public enum ZoomBlurFilter: Filter {
    public static let name = "zoom-blur"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let (cx, cy) = try FilterArgValue.keyedPoint(args, key: "center", default: (0.5, 0.5), filter: name)
        let amount = try FilterArgValue.keyedNumber(args, key: "amount", default: 20.0, filter: name)
        let target = image.foreground.extent
        let center = CIVector(x: target.width * cx, y: target.height * (1 - cy))
        return try PixelFilterHelper.applyCI(name: "CIZoomBlur", params: ["inputCenter": center, "inputAmount": amount], to: image, on: layer, humanName: name)
    }
}

public enum UnsharpFilter: Filter {
    public static let name = "unsharp"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let positional = try FilterArgValue.positionalNumbers(args, defaults: [2.5, 0.5], filter: name)
        let radius = try FilterArgValue.keyedNumber(args, key: "radius", default: positional[0], filter: name)
        let intensity = try FilterArgValue.keyedNumber(args, key: "intensity", default: positional[1], filter: name)
        return try PixelFilterHelper.applyCI(name: "CIUnsharpMask", params: ["inputRadius": radius, "inputIntensity": intensity], to: image, on: layer, humanName: name)
    }
}

public enum PixelateFilter: Filter {
    public static let name = "pixelate"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let size = try PixelFilterHelper.floatArg(args, default: 8.0)
        let center = CIVector(x: image.foreground.extent.midX, y: image.foreground.extent.midY)
        return try PixelFilterHelper.applyCI(name: "CIPixellate", params: ["inputScale": size, "inputCenter": center], to: image, on: layer, humanName: name)
    }
}

public enum EdgeWorkFilter: Filter {
    public static let name = "edge-work"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let radius = try PixelFilterHelper.floatArg(args, default: 3.0)
        return try PixelFilterHelper.applyCI(name: "CIEdgeWork", params: ["inputRadius": radius], to: image, on: layer, humanName: name, forceOpaque: true)
    }
}

public enum CrystallizeFilter: Filter {
    public static let name = "crystallize"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let radius = try PixelFilterHelper.floatArg(args, default: 20.0)
        let center = CIVector(x: image.foreground.extent.midX, y: image.foreground.extent.midY)
        return try PixelFilterHelper.applyCI(name: "CICrystallize", params: ["inputRadius": radius, "inputCenter": center], to: image, on: layer, humanName: name)
    }
}

public enum PointillizeFilter: Filter {
    public static let name = "pointillize"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let radius = try PixelFilterHelper.floatArg(args, default: 10.0)
        let center = CIVector(x: image.foreground.extent.midX, y: image.foreground.extent.midY)
        return try PixelFilterHelper.applyCI(name: "CIPointillize", params: ["inputRadius": radius, "inputCenter": center], to: image, on: layer, humanName: name)
    }
}

public enum OpacityFilter: Filter {
    public static let name = "opacity"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let value = try PixelFilterHelper.requireRange(
            PixelFilterHelper.floatArg(args, default: 1.0),
            0.0...1.0,
            name: "value",
            filter: name
        )
        let aVector = CIVector(x: 0, y: 0, z: 0, w: CGFloat(value))
        return try PixelFilterHelper.applyCI(name: "CIColorMatrix", params: ["inputAVector": aVector], to: image, on: layer, humanName: name)
    }
}

public enum TintFilter: Filter {
    public static let name = "tint"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let color = try FilterArgValue.keyedColor(args, default: RGBA(r: 1, g: 1, b: 1, a: 1), filter: name)
        let amount = try FilterArgValue.keyedNumber(args, key: "amount", default: 0.5, filter: name)
        // Use CIColorMonochrome at lower intensity for the tint effect.
        let ci = CIColor(red: CGFloat(color.r), green: CGFloat(color.g), blue: CGFloat(color.b))
        return try PixelFilterHelper.applyCI(name: "CIColorMonochrome", params: ["inputColor": ci, "inputIntensity": amount], to: image, on: layer, humanName: name)
    }
}

public enum ColorizeFilter: Filter {
    public static let name = "colorize"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let color = try FilterArgValue.keyedColor(args, default: RGBA(r: 0.5, g: 0.5, b: 0.5, a: 1), filter: name)
        let amount = try FilterArgValue.keyedNumber(args, key: "amount", default: 1.0, filter: name)
        let ci = CIColor(red: CGFloat(color.r), green: CGFloat(color.g), blue: CGFloat(color.b))
        return try PixelFilterHelper.applyCI(name: "CIColorMonochrome", params: ["inputColor": ci, "inputIntensity": amount], to: image, on: layer, humanName: name)
    }
}

public enum LevelsFilter: Filter {
    public static let name = "levels"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        // Maps black->0, white->1, with gamma midpoint. Use CIGammaAdjust + CIColorClamp for a simple, working levels.
        var black = try FilterArgValue.keyedNumber(args, key: "black", default: 0.0, filter: name)
        var white = try FilterArgValue.keyedNumber(args, key: "white", default: 1.0, filter: name)
        let gamma = try FilterArgValue.keyedNumber(args, key: "gamma", default: 1.0, filter: name)
        black = try normalizedLevelEndpoint(black, name: "black")
        white = try normalizedLevelEndpoint(white, name: "white")
        // Apply a CIColorMatrix that maps [black, white] -> [0, 1], then gamma.
        let scale = white > black ? CGFloat(1.0 / (white - black)) : 1.0
        let offset = CGFloat(-black) * scale
        var step = image
        let matrixParams: [String: Any] = [
            "inputRVector": CIVector(x: scale, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: scale, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: scale, w: 0),
            "inputBiasVector": CIVector(x: offset, y: offset, z: offset, w: 0),
        ]
        step = try PixelFilterHelper.applyCI(name: "CIColorMatrix", params: matrixParams, to: step, on: layer, humanName: name)
        if gamma != 1.0 {
            step = try PixelFilterHelper.applyCI(name: "CIGammaAdjust", params: ["inputPower": gamma], to: step, on: layer, humanName: name)
        }
        return step
    }

    private static func normalizedLevelEndpoint(_ value: Double, name argName: String) throws -> Double {
        guard (0.0...255.0).contains(value) else {
            throw BgBgOneError.parser(
                ErrorCodes.parseFlagValueInvalid,
                "filter levels: \(argName) must be 0..255, got \(value)",
                origin: "--filter",
                context: ["filter": name, "arg": argName, "value": String(value)]
            )
        }
        let normalized = value > 1.0 ? value / 255.0 : value
        return normalized
    }
}

public enum DuotoneFilter: Filter {
    public static let name = "duotone"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        let dark = try FilterArgValue.keyedColor(args, key: "dark", default: RGBA(r: 0, g: 0, b: 0, a: 1), filter: name)
        let light = try FilterArgValue.keyedColor(args, key: "light", default: RGBA(r: 1, g: 1, b: 1, a: 1), filter: name)
        // Implement duotone as: grayscale, then map black->dark and white->light via CIColorMatrix.
        var step = try GrayscaleFilter.apply(args: [], to: image, on: layer)
        let dr = CGFloat(light.r - dark.r), dg = CGFloat(light.g - dark.g), db = CGFloat(light.b - dark.b)
        let or = CGFloat(dark.r), og = CGFloat(dark.g), ob = CGFloat(dark.b)
        let params: [String: Any] = [
            "inputRVector": CIVector(x: dr, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: dg, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: db, w: 0),
            "inputBiasVector": CIVector(x: or, y: og, z: ob, w: 0),
        ]
        step = try PixelFilterHelper.applyCI(name: "CIColorMatrix", params: params, to: step, on: layer, humanName: name)
        return step
    }
}
