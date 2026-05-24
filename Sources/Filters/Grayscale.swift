import Foundation
import CoreImage
import BgBgOneCore

/// T5 #7 — `grayscale` filter. Sets saturation to 0 on the chosen layer.
/// Backed by `CIColorControls`. Valid on `fg`, `bg`, and `all`.
public enum GrayscaleFilter: Filter {
    public static let name = "grayscale"
    public static let validLayers: Set<FilterLayer> = [.fg, .bg, .all]

    public static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage {
        var out = image
        switch layer {
        case .fg:
            out.foreground = try desaturate(image.foreground)
        case .bg:
            out.background = try desaturate(image.background)
        case .all:
            out.foreground = try desaturate(image.foreground)
            out.background = try desaturate(image.background)
        case .mask:
            throw BgBgOneError.parser(
                ErrorCodes.parseFlagValueInvalid,
                "filter grayscale does not accept layer mask",
                origin: "--filter",
                context: ["name": name, "layer": "mask"]
            )
        case .composite:
            throw BgBgOneError.parser(
                ErrorCodes.parseFlagValueInvalid,
                "filter grayscale does not accept layer composite",
                origin: "--filter",
                context: ["name": name, "layer": "composite"]
            )
        }
        return out
    }

    private static func desaturate(_ image: CIImage) throws -> CIImage {
        guard let filter = CIFilter(name: "CIColorControls") else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkVisionFail, "CIColorControls unavailable")
        }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(0.0, forKey: "inputSaturation")
        guard let out = filter.outputImage else {
            throw BgBgOneError.frameworkError(ErrorCodes.frameworkComposeFail, "grayscale: no output")
        }
        return out
    }
}
