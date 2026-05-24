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
    /// `mask` MUST be DeviceGray (8-bit) so the alpha clip path is stable.
    public static func executeAndFlatten(
        foreground: CGImage,
        mask: CGImage,
        background: CGImage,
        canvas: CGRect,
        chains: [FilterChain]
    ) throws -> CGImage {
        let maskCI = try alignedMask(mask, to: foreground)
        var layered = LayeredImage(
            foreground: CIImage(cgImage: foreground),
            foregroundMask: maskCI,
            background: CIImage(cgImage: background),
            canvas: canvas
        )
        for chain in chains {
            for stage in chain.stages {
                for call in stage.calls {
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

    /// Vision returns segmentation masks at a downsampled resolution (e.g.
    /// 2016x1512 for a 3781x2389 source). CIBlendWithMask does not auto-scale
    /// the mask to match the foreground extent — it treats out-of-extent
    /// samples as transparent, which would project the entire matte into the
    /// foreground's bottom-left quadrant. Resample the mask to the foreground
    /// dimensions so every layer shares the same coordinate system.
    private static func alignedMask(_ mask: CGImage, to foreground: CGImage) throws -> CIImage {
        let maskCI = CIImage(cgImage: mask)
        let fgW = CGFloat(foreground.width)
        let fgH = CGFloat(foreground.height)
        let maskW = maskCI.extent.width
        let maskH = maskCI.extent.height
        guard maskW > 0, maskH > 0 else {
            throw BgBgOneError.frameworkError(
                ErrorCodes.frameworkComposeFail,
                "filter pipeline: mask has zero extent"
            )
        }
        if abs(maskW - fgW) < 0.5 && abs(maskH - fgH) < 0.5 {
            return maskCI
        }
        let sx = fgW / maskW
        let sy = fgH / maskH
        let transform = CGAffineTransform(scaleX: sx, y: sy)
        return maskCI.transformed(by: transform).cropped(to: CGRect(x: 0, y: 0, width: fgW, height: fgH))
    }

    /// Composite `LayeredImage` into a single `CGImage`:
    /// paint background; over that, paint foreground with the mask as alpha.
    static func flatten(_ layered: LayeredImage) throws -> CGImage {
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
        let cropped = out.cropped(to: layered.canvas)
        guard let cg = ciContext.createCGImage(cropped, from: layered.canvas) else {
            throw BgBgOneError.frameworkError(
                ErrorCodes.frameworkComposeFail,
                "filter pipeline flatten: cannot rasterise composite"
            )
        }
        return cg
    }
}
