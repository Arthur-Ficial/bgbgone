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
        var radius = 20.0, angle = 0.0
        for a in args {
            switch a {
            case .value(let v): if let d = Double(v) { radius = d }
            case .keyed(let k, let v):
                if let d = Double(v) {
                    switch k.lowercased() {
                    case "radius": radius = d
                    case "angle":  angle = d * .pi / 180
                    default: break
                    }
                }
            }
        }
        return try PixelFilterHelper.applyCI(name: "CIMotionBlur", params: ["inputRadius": radius, "inputAngle": angle], to: image, on: layer, humanName: name)
    }
}

public enum ZoomBlurFilter: Filter {
    public static let name = "zoom-blur"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        var cx = 0.5, cy = 0.5, amount = 20.0
        for a in args {
            if case .keyed(let k, let v) = a {
                switch k.lowercased() {
                case "center":
                    let parts = v.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
                    if parts.count == 2 { cx = parts[0]; cy = parts[1] }
                case "amount":
                    if let d = Double(v) { amount = d }
                default: break
                }
            }
        }
        let target = image.foreground.extent
        let center = CIVector(x: target.width * cx, y: target.height * (1 - cy))
        return try PixelFilterHelper.applyCI(name: "CIZoomBlur", params: ["inputCenter": center, "inputAmount": amount], to: image, on: layer, humanName: name)
    }
}

public enum UnsharpFilter: Filter {
    public static let name = "unsharp"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        var radius = 2.5, intensity = 0.5
        for a in args {
            if case .keyed(let k, let v) = a, let d = Double(v) {
                switch k.lowercased() {
                case "radius": radius = d
                case "intensity": intensity = d
                default: break
                }
            } else if case .value(let v) = a, let d = Double(v) {
                radius = d
            }
        }
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
        return try PixelFilterHelper.applyCI(name: "CIEdgeWork", params: ["inputRadius": radius], to: image, on: layer, humanName: name)
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
        let value = max(0, min(1, try PixelFilterHelper.floatArg(args, default: 1.0)))
        let aVector = CIVector(x: 0, y: 0, z: 0, w: CGFloat(value))
        return try PixelFilterHelper.applyCI(name: "CIColorMatrix", params: ["inputAVector": aVector], to: image, on: layer, humanName: name)
    }
}

public enum TintFilter: Filter {
    public static let name = "tint"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        var color = RGBA(r: 1, g: 1, b: 1, a: 1)
        var amount = 0.5
        for a in args {
            if case .keyed(let k, let v) = a {
                switch k.lowercased() {
                case "color": color = (try? ColourParser.parse(v)) ?? color
                case "amount": amount = Double(v) ?? amount
                default: break
                }
            }
        }
        // Use CIColorMonochrome at lower intensity for the tint effect.
        let ci = CIColor(red: CGFloat(color.r), green: CGFloat(color.g), blue: CGFloat(color.b))
        return try PixelFilterHelper.applyCI(name: "CIColorMonochrome", params: ["inputColor": ci, "inputIntensity": amount], to: image, on: layer, humanName: name)
    }
}

public enum ColorizeFilter: Filter {
    public static let name = "colorize"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        var color = RGBA(r: 0.5, g: 0.5, b: 0.5, a: 1)
        var amount = 1.0
        for a in args {
            if case .keyed(let k, let v) = a {
                switch k.lowercased() {
                case "color": color = (try? ColourParser.parse(v)) ?? color
                case "amount": amount = Double(v) ?? amount
                default: break
                }
            }
        }
        let ci = CIColor(red: CGFloat(color.r), green: CGFloat(color.g), blue: CGFloat(color.b))
        return try PixelFilterHelper.applyCI(name: "CIColorMonochrome", params: ["inputColor": ci, "inputIntensity": amount], to: image, on: layer, humanName: name)
    }
}

public enum LevelsFilter: Filter {
    public static let name = "levels"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        // Maps black->0, white->1, with gamma midpoint. Use CIGammaAdjust + CIColorClamp for a simple, working levels.
        var black = 0.0, white = 1.0, gamma = 1.0
        for a in args {
            if case .keyed(let k, let v) = a, let d = Double(v) {
                switch k.lowercased() {
                case "black": black = d
                case "white": white = d
                case "gamma": gamma = d
                default: break
                }
            }
        }
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
}

public enum DuotoneFilter: Filter {
    public static let name = "duotone"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]
    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        var dark = RGBA(r: 0, g: 0, b: 0, a: 1)
        var light = RGBA(r: 1, g: 1, b: 1, a: 1)
        for a in args {
            if case .keyed(let k, let v) = a {
                switch k.lowercased() {
                case "dark": dark = (try? ColourParser.parse(v)) ?? dark
                case "light": light = (try? ColourParser.parse(v)) ?? light
                default: break
                }
            }
        }
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
