import Foundation
import CoreImage
import BgBgOneCore

/// Per-layer image bundle that flows through the filter chain. The pipeline
/// builds one of these after Apple Vision produces the matte; filters consume
/// and return a new `LayeredImage`; the flatten step composites it into the
/// final CGImage via the shared `CIContext`.
public struct LayeredImage {
    /// Original subject pixels, full frame, NOT pre-multiplied by the mask.
    public var foreground: CIImage
    /// Single-channel float mask, 0..1. Same extent as `foreground`.
    public var foregroundMask: CIImage
    /// Background plate, sized to canvas.
    public var background: CIImage
    /// Canvas rect in pixel space.
    public var canvas: CGRect

    public init(foreground: CIImage, foregroundMask: CIImage, background: CIImage, canvas: CGRect) {
        self.foreground = foreground
        self.foregroundMask = foregroundMask
        self.background = background
        self.canvas = canvas
    }
}

/// Every filter ticket implements this protocol. Pure function on
/// `LayeredImage`; no globals; no per-run state.
public protocol Filter {
    static var name: String { get }
    static var validLayers: Set<FilterLayer> { get }
    static func apply(args: [FilterArg], to image: LayeredImage, on layer: FilterLayer) throws -> LayeredImage
}

/// Static dispatch table. Filters are added here as their tickets ship
/// (one `case` per filter). Swift 6 strict concurrency forbids mutable
/// global state, so we use a `switch` on lowercased name rather than a
/// runtime dictionary. The `FilterCatalogue` manifest in BgBgOneCore is
/// the user-facing surface; this is the internal dispatch.
public enum FilterDispatch {
    public static func apply(
        name: String,
        args: [FilterArg],
        to image: LayeredImage,
        on layer: FilterLayer
    ) throws -> LayeredImage {
        switch name.lowercased() {
        case GrayscaleFilter.name:
            return try GrayscaleFilter.apply(args: args, to: image, on: layer)
        case DesaturateFilter.name:
            return try DesaturateFilter.apply(args: args, to: image, on: layer)
        case NegateFilter.name:
            return try NegateFilter.apply(args: args, to: image, on: layer)
        case SepiaFilter.name:
            return try SepiaFilter.apply(args: args, to: image, on: layer)
        case GammaFilter.name:
            return try GammaFilter.apply(args: args, to: image, on: layer)
        case ExposureFilter.name:
            return try ExposureFilter.apply(args: args, to: image, on: layer)
        case HueFilter.name:
            return try HueFilter.apply(args: args, to: image, on: layer)
        case VibranceFilter.name:
            return try VibranceFilter.apply(args: args, to: image, on: layer)
        case BlurFilter.name:
            return try BlurFilter.apply(args: args, to: image, on: layer)
        case BoxBlurFilter.name:
            return try BoxBlurFilter.apply(args: args, to: image, on: layer)
        case SharpenFilter.name:
            return try SharpenFilter.apply(args: args, to: image, on: layer)
        case PosterizeFilter.name:
            return try PosterizeFilter.apply(args: args, to: image, on: layer)
        case EdgesFilter.name:
            return try EdgesFilter.apply(args: args, to: image, on: layer)
        case ComicFilter.name:
            return try ComicFilter.apply(args: args, to: image, on: layer)
        case AdjustFilter.name:
            return try AdjustFilter.apply(args: args, to: image, on: layer)
        // Cases added per filter ticket in S3..S8.
        default:
            // Unreachable when the registry manifest agrees with this dispatch.
            // The parser-level FilterRegistry.validate(chain) catches unknown
            // names BEFORE the pipeline runs, so reaching this default means
            // catalogue and dispatch are out of sync (programmer error).
            throw BgBgOneError.frameworkError(
                ErrorCodes.frameworkInternalInvariant,
                "no dispatch for filter \(name) (catalogue and FilterDispatch out of sync)"
            )
        }
    }
}
