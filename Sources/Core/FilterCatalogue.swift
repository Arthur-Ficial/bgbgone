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
        // T13 #15 tint - SHIPPED
        .init(name: "tint", validLayers: [.fg, .bg, .all], signature: "tint=color=#hex:amount=A", doc: "blend toward a tint colour (CIColorMonochrome)"),
        // T14 #16 colorize - SHIPPED
        .init(name: "colorize", validLayers: [.fg, .bg, .all], signature: "colorize=color=#hex:amount=A", doc: "monochrome at a target colour (CIColorMonochrome)"),
        // T15 #17 temperature - SHIPPED
        .init(name: "temperature", validLayers: [.fg, .bg, .all], signature: "temperature=K", doc: "shift colour temperature in Kelvin (CITemperatureAndTint)"),
        // T16 #18 levels - SHIPPED
        .init(name: "levels", validLayers: [.fg, .bg, .all], signature: "levels=black=B:white=W:gamma=G", doc: "Photoshop-style levels (CIColorMatrix + CIGammaAdjust)"),
        // T18 #20 opacity - SHIPPED
        .init(name: "opacity", validLayers: [.fg, .bg, .all], signature: "opacity=value", doc: "scale alpha by value 0..1 (CIColorMatrix)", producesAlpha: true),
        // T19 #21 duotone - SHIPPED
        .init(name: "duotone", validLayers: [.fg, .bg, .all], signature: "duotone=dark=#hex:light=#hex", doc: "two-colour map by luminance (CIColorMatrix)"),
        // T22 #24 motion-blur - SHIPPED
        .init(name: "motion-blur", validLayers: [.fg, .bg, .all], signature: "motion-blur=radius:angle", doc: "directional blur (CIMotionBlur)"),
        // T23 #25 zoom-blur - SHIPPED
        .init(name: "zoom-blur", validLayers: [.fg, .bg, .all], signature: "zoom-blur=center=X,Y:amount=A", doc: "radial zoom blur (CIZoomBlur)"),
        // T25 #27 unsharp - SHIPPED
        .init(name: "unsharp", validLayers: [.fg, .bg, .all], signature: "unsharp=radius:intensity", doc: "unsharp mask (CIUnsharpMask)"),
        // T27 #29 pixelate - SHIPPED
        .init(name: "pixelate", validLayers: [.fg, .bg, .all], aliases: ["mosaic"], signature: "pixelate=size", doc: "block pixelation, alias mosaic (CIPixellate)"),
        // T29 #31 edge-work - SHIPPED
        .init(name: "edge-work", validLayers: [.fg, .bg, .all], signature: "edge-work=radius", doc: "line-art edges (CIEdgeWork)"),
        // T31 #33 crystallize - SHIPPED
        .init(name: "crystallize", validLayers: [.fg, .bg, .all], signature: "crystallize=radius", doc: "Voronoi mosaic (CICrystallize)"),
        // T32 #34 pointillize - SHIPPED
        .init(name: "pointillize", validLayers: [.fg, .bg, .all], signature: "pointillize=radius", doc: "Seurat dot effect (CIPointillize)"),
        // T30 #32 emboss - SHIPPED
        .init(name: "emboss", validLayers: [.fg, .bg, .all], signature: "emboss", doc: "raised relief via 3x3 convolution"),
        // T34 #36 noise - SHIPPED
        .init(name: "noise", validLayers: [.fg, .bg, .all], signature: "noise=amount", doc: "additive film grain (CIRandomGenerator + composite)"),
        // T35 #37 vignette - SHIPPED (composite-only)
        .init(name: "vignette", validLayers: [.all], signature: "vignette=intensity:radius", doc: "darken edges, composite only (CIVignette)"),
        // T36 #38 vignette-effect - SHIPPED (composite-only)
        .init(name: "vignette-effect", validLayers: [.all], signature: "vignette-effect=center=X,Y:radius=R:intensity=I", doc: "positioned vignette (CIVignetteEffect)"),
        // T37 #39 bloom - SHIPPED (composite-only)
        .init(name: "bloom", validLayers: [.all], signature: "bloom=intensity:radius", doc: "soft glow on highlights (CIBloom)"),
        // T38 #40 gloom - SHIPPED (composite-only)
        .init(name: "gloom", validLayers: [.all], signature: "gloom=intensity:radius", doc: "dark-glow inverse of bloom (CIGloom)"),
        // T50 #52 feather - SHIPPED (mask-only)
        .init(name: "feather", validLayers: [.mask], signature: "feather=radius", doc: "soften matte edge (CIGaussianBlur on mask)"),
        // T51 #53 threshold - SHIPPED (mask-only)
        .init(name: "threshold", validLayers: [.mask], signature: "threshold=value", doc: "binarise matte (CIColorThreshold)"),
        // T52 #54 expand - SHIPPED (mask-only)
        .init(name: "expand", validLayers: [.mask], signature: "expand=pixels", doc: "grow matte dilation (CIMorphologyMaximum)"),
        // T53 #55 contract - SHIPPED (mask-only)
        .init(name: "contract", validLayers: [.mask], signature: "contract=pixels", doc: "shrink matte erosion (CIMorphologyMinimum)"),
        // T39 #41 outline - SHIPPED (fg-only)
        .init(name: "outline", validLayers: [.fg], signature: "outline=color=#hex:width=N", doc: "coloured outline outside the matte (morphology+subtract+tint)", producesAlpha: true),
        // T40 #42 glow - SHIPPED (fg-only)
        .init(name: "glow", validLayers: [.fg], signature: "glow=color=#hex:radius=R:intensity=I", doc: "subject glow halo (blur+tint+composite)", producesAlpha: true),
        // T41 #43 shadow - SHIPPED (fg-only)
        .init(name: "shadow", validLayers: [.fg], signature: "shadow=blur=B:offset=X,Y:opacity=O:color=#hex", doc: "per-subject drop shadow (translate+blur+tint+composite)", producesAlpha: true),
        // T42 #44 inner-shadow - SHIPPED (fg-only)
        .init(name: "inner-shadow", validLayers: [.fg], signature: "inner-shadow=blur=B:offset=X,Y:opacity=O:color=#hex", doc: "shadow inside the matte (invert+blur+intersect+tint)"),
        // T43 #45 silhouette - SHIPPED (fg-only)
        .init(name: "silhouette", validLayers: [.fg], signature: "silhouette=color=#hex", doc: "fill the subject with one colour"),
        // T44 #46 cutout - SHIPPED (fg-only)
        .init(name: "cutout", validLayers: [.fg], signature: "cutout", doc: "subject becomes a hole; background stays", producesAlpha: true),
        // T45 #47 matte - SHIPPED (fg-only)
        .init(name: "matte", validLayers: [.fg], signature: "matte", doc: "emit the alpha mask itself as final RGBA", producesAlpha: true),
        // T46 #48 scale - SHIPPED (fg-only geometric)
        .init(name: "scale", validLayers: [.fg], signature: "scale=factor", doc: "scale subject around centre (CIAffineTransform)"),
        // T47 #49 translate - SHIPPED (fg-only geometric)
        .init(name: "translate", validLayers: [.fg], signature: "translate=dx,dy", doc: "shift subject in pixels (CIAffineTransform)"),
        // T48 #50 rotate - SHIPPED (fg-only geometric)
        .init(name: "rotate", validLayers: [.fg], signature: "rotate=degrees", doc: "rotate subject around centre (CIAffineTransform)"),
        // T49 #51 flip - SHIPPED (fg-only geometric)
        .init(name: "flip", validLayers: [.fg], signature: "flip=horizontal|vertical", doc: "mirror subject (CIAffineTransform)"),
    ]
}
