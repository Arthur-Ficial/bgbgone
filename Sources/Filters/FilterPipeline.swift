import Foundation
import CoreImage
import CoreGraphics
import BgBgOneCore

/// Layered-image filter executor. Builds a `LayeredImage` from the
/// post-Vision mask + the chosen background, walks every filter chain
/// in `cfg.filters`, dispatches each call to `FilterDispatch.apply`,
/// then rasterises the result to the final composited `CGImage`.
public enum FilterPipeline {
    /// Shared Core Image context for the whole pipeline. One instance,
    /// no caching of intermediates (per the design doc).
    public static let ciContext = CIContext(options: [.cacheIntermediates: false])

    /// Run every chain over the layered image and rasterise the result.
    /// `mask` MUST be DeviceGray (8-bit) AND already at the source extent.
    /// `ForegroundMask.resultFromMaskPixelBuffer` is the single source of
    /// truth for mask resolution — see CLAUDE.md "root-cause fixes only".
    public static func executeAndFlatten(
        foreground: CGImage,
        mask: CGImage,
        background: CGImage,
        canvas: CGRect,
        chains: [FilterChain]
    ) throws -> CGImage {
        var layered = LayeredImage(
            foreground: CIImage(cgImage: foreground),
            foregroundMask: CIImage(cgImage: mask),
            background: CIImage(cgImage: background),
            canvas: canvas
        )
        for chain in chains {
            for stage in chain.stages {
                for call in stage.calls {
                    if stage.layer == .composite {
                        if layered.composite == nil {
                            layered.composite = try flattenCI(layered)
                        }
                    } else if layered.composite != nil {
                        throw BgBgOneError.parser(
                            ErrorCodes.parseFlagValueInvalid,
                            "layer \(stage.layer.rawValue) cannot run after composite: the foreground/background split is already flattened",
                            origin: "--filter",
                            context: ["layer": stage.layer.rawValue, "filter": call.name],
                            hint: "move fg:/bg:/all:/mask: stages before the composite: stage"
                        )
                    }
                    layered = try FilterDispatch.apply(
                        name: call.name,
                        args: call.args,
                        to: layered,
                        on: stage.layer
                    )
                }
            }
        }
        return try flatten(layered)
    }

    static func flattenCI(_ layered: LayeredImage) throws -> CIImage {
        let blendFilter = CIFilter(name: "CIBlendWithMask")!
        blendFilter.setValue(layered.foreground, forKey: kCIInputImageKey)
        blendFilter.setValue(layered.background, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(layered.foregroundMask, forKey: kCIInputMaskImageKey)
        guard let out = blendFilter.outputImage else {
            throw BgBgOneError.frameworkError(
                ErrorCodes.frameworkComposeFail,
                "filter pipeline flatten: CIBlendWithMask produced no output"
            )
        }
        return out.cropped(to: layered.canvas)
    }

    /// Composite `LayeredImage` into a single `CGImage`:
    /// paint background; over that, paint foreground with the mask as alpha.
    static func flatten(_ layered: LayeredImage) throws -> CGImage {
        let cropped = try layered.composite ?? flattenCI(layered)
        guard let cg = ciContext.createCGImage(cropped, from: layered.canvas) else {
            throw BgBgOneError.frameworkError(
                ErrorCodes.frameworkComposeFail,
                "filter pipeline flatten: cannot rasterise composite"
            )
        }
        return cg
    }
}
