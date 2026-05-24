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
    /// Flattened image after a `composite:` stage. Once present, foreground /
    /// background / mask stages may not follow because the layer split is gone.
    public var composite: CIImage?

    public init(foreground: CIImage, foregroundMask: CIImage, background: CIImage, canvas: CGRect, composite: CIImage? = nil) {
        self.foreground = foreground
        self.foregroundMask = foregroundMask
        self.background = background
        self.canvas = canvas
        self.composite = composite
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
        case TemperatureFilter.name:
            return try TemperatureFilter.apply(args: args, to: image, on: layer)
        case MotionBlurFilter.name:
            return try MotionBlurFilter.apply(args: args, to: image, on: layer)
        case ZoomBlurFilter.name:
            return try ZoomBlurFilter.apply(args: args, to: image, on: layer)
        case UnsharpFilter.name:
            return try UnsharpFilter.apply(args: args, to: image, on: layer)
        case PixelateFilter.name:
            return try PixelateFilter.apply(args: args, to: image, on: layer)
        case EdgeWorkFilter.name:
            return try EdgeWorkFilter.apply(args: args, to: image, on: layer)
        case CrystallizeFilter.name:
            return try CrystallizeFilter.apply(args: args, to: image, on: layer)
        case PointillizeFilter.name:
            return try PointillizeFilter.apply(args: args, to: image, on: layer)
        case OpacityFilter.name:
            return try OpacityFilter.apply(args: args, to: image, on: layer)
        case TintFilter.name:
            return try TintFilter.apply(args: args, to: image, on: layer)
        case ColorizeFilter.name:
            return try ColorizeFilter.apply(args: args, to: image, on: layer)
        case LevelsFilter.name:
            return try LevelsFilter.apply(args: args, to: image, on: layer)
        case DuotoneFilter.name:
            return try DuotoneFilter.apply(args: args, to: image, on: layer)
        case VignetteFilter.name:
            return try VignetteFilter.apply(args: args, to: image, on: layer)
        case VignetteEffectFilter.name:
            return try VignetteEffectFilter.apply(args: args, to: image, on: layer)
        case BloomFilter.name:
            return try BloomFilter.apply(args: args, to: image, on: layer)
        case GloomFilter.name:
            return try GloomFilter.apply(args: args, to: image, on: layer)
        case EmbossFilter.name:
            return try EmbossFilter.apply(args: args, to: image, on: layer)
        case NoiseFilter.name:
            return try NoiseFilter.apply(args: args, to: image, on: layer)
        case FeatherFilter.name:
            return try FeatherFilter.apply(args: args, to: image, on: layer)
        case ThresholdFilter.name:
            return try ThresholdFilter.apply(args: args, to: image, on: layer)
        case ExpandFilter.name:
            return try ExpandFilter.apply(args: args, to: image, on: layer)
        case ContractFilter.name:
            return try ContractFilter.apply(args: args, to: image, on: layer)
        case SilhouetteFilter.name:
            return try SilhouetteFilter.apply(args: args, to: image, on: layer)
        case CutoutFilter.name:
            return try CutoutFilter.apply(args: args, to: image, on: layer)
        case MatteFilter.name:
            return try MatteFilter.apply(args: args, to: image, on: layer)
        case OutlineFilter.name:
            return try OutlineFilter.apply(args: args, to: image, on: layer)
        case GlowFilter.name:
            return try GlowFilter.apply(args: args, to: image, on: layer)
        case ShadowFilter.name:
            return try ShadowFilter.apply(args: args, to: image, on: layer)
        case InnerShadowFilter.name:
            return try InnerShadowFilter.apply(args: args, to: image, on: layer)
        case ScaleFilter.name:
            return try ScaleFilter.apply(args: args, to: image, on: layer)
        case TranslateFilter.name:
            return try TranslateFilter.apply(args: args, to: image, on: layer)
        case RotateFilter.name:
            return try RotateFilter.apply(args: args, to: image, on: layer)
        case FlipFilter.name:
            return try FlipFilter.apply(args: args, to: image, on: layer)
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
