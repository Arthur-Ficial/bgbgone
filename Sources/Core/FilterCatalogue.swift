import Foundation

/// The published filter catalogue. Empty at T2; one entry is appended for
/// every filter that actually ships with a real implementation in S3..S8.
/// NEVER add an entry here without the matching `Sources/Filters/<Name>.swift`
/// implementation, a registered dispatch in the pipeline, a passing unit-test
/// pixel assertion, and a per-filter doc.
public enum FilterCatalogue {
    public static let all: [FilterManifestEntry] = [
        // T5 #7 grayscale - SHIPPED
        .init(name: "grayscale", validLayers: [.fg, .bg, .all], signature: "grayscale", doc: "remove all colour saturation (CIColorControls)"),
        // T6 #8 desaturate - SHIPPED
        .init(name: "desaturate", validLayers: [.fg, .bg, .all], signature: "desaturate=amount", doc: "scale saturation by 1-amount (CIColorControls)"),
        // T7 #9 negate - SHIPPED
        .init(name: "negate", validLayers: [.fg, .bg, .all], signature: "negate", doc: "invert RGB (CIColorInvert)"),
        // T8 #10 sepia - SHIPPED
        .init(name: "sepia", validLayers: [.fg, .bg, .all], signature: "sepia=intensity", doc: "warm-tinted monochrome 0..1 (CISepiaTone)"),
        // T9 #11 adjust - SHIPPED
        .init(name: "adjust", validLayers: [.fg, .bg, .all], signature: "adjust=brightness=B:contrast=C:saturation=S", doc: "brightness/contrast/saturation in one call (CIColorControls)"),
        // T10 #12 gamma - SHIPPED
        .init(name: "gamma", validLayers: [.fg, .bg, .all], signature: "gamma=value", doc: "gamma curve, typical 0.5..2.5 (CIGammaAdjust)"),
        // T11 #13 exposure - SHIPPED
        .init(name: "exposure", validLayers: [.fg, .bg, .all], signature: "exposure=stops", doc: "+/- stops, typical -2..+2 (CIExposureAdjust)"),
        // T12 #14 hue - SHIPPED
        .init(name: "hue", validLayers: [.fg, .bg, .all], signature: "hue=degrees", doc: "rotate hue by N degrees (CIHueAdjust)"),
        // T17 #19 vibrance - SHIPPED
        .init(name: "vibrance", validLayers: [.fg, .bg, .all], signature: "vibrance=amount", doc: "boost low-saturation colours (CIVibrance)"),
        // T20 #22 blur - SHIPPED
        .init(name: "blur", validLayers: [.fg, .bg, .all], signature: "blur=radius", doc: "Gaussian blur, radius in px (CIGaussianBlur)"),
        // T21 #23 box-blur - SHIPPED
        .init(name: "box-blur", validLayers: [.fg, .bg, .all], signature: "box-blur=radius", doc: "box (mean) blur (CIBoxBlur)"),
        // T24 #26 sharpen - SHIPPED
        .init(name: "sharpen", validLayers: [.fg, .bg, .all], signature: "sharpen=amount", doc: "luminance sharpen (CISharpenLuminance)"),
        // T26 #28 posterize - SHIPPED
        .init(name: "posterize", validLayers: [.fg, .bg, .all], signature: "posterize=levels", doc: "quantise to N colour levels (CIColorPosterize)"),
        // T28 #30 edges - SHIPPED
        .init(name: "edges", validLayers: [.fg, .bg, .all], signature: "edges=intensity", doc: "edge detection (CIEdges)"),
        // T33 #35 comic - SHIPPED
        .init(name: "comic", validLayers: [.fg, .bg, .all], signature: "comic", doc: "halftone comic-book effect (CIComicEffect)"),
    ]
}
