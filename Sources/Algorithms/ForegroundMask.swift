import Foundation
import CoreGraphics
import CoreImage
import Vision
import BgBgOneCore

struct MaskedResult {
    /// The original image with non-foreground pixels made transparent.
    let maskedImage: CGImage
    /// The alpha mask itself (grayscale), useful for compositing custom backgrounds.
    let mask: CGImage
    /// Which algorithm actually ran (after `auto` resolution).
    let algoUsed: String
}

enum ForegroundMask {

    /// Apply the chosen (or auto-picked) algorithm and return the masked image + mask.
    static func maskedImage(from image: CGImage, algo: Algo) throws -> MaskedResult {
        let resolved = resolve(algo)
        switch resolved {
        case .vnMask, .vnRemove, .auto:
            return try runForegroundInstanceMask(on: image, algoLabel: resolved.rawValue)
        case .person, .sky, .saliency:
            // Stub for now — implemented in later TDD cycles. Falls back to vn-mask so the
            // pipeline still produces a result while we build out alternatives.
            return try runForegroundInstanceMask(on: image, algoLabel: resolved.rawValue)
        }
    }

    /// Same as `maskedImage(from:algo:)` but returns one MaskedResult per detected instance.
    /// If only one instance is detected, returns an array of size 1 — callers should usually
    /// fall back to the single-result path in that case.
    static func maskedImages(from image: CGImage, algo: Algo) throws -> [MaskedResult] {
        let resolved = resolve(algo)
        switch resolved {
        case .vnMask, .vnRemove, .auto, .person, .sky, .saliency:
            return try runForegroundInstanceMaskPerInstance(on: image, algoLabel: resolved.rawValue)
        }
    }

    private static func resolve(_ algo: Algo) -> Algo {
        if algo != .auto { return algo }
        // `auto`: prefer the most-modern, highest-quality available API.
        if CapabilityProbe.isVNRemoveBackgroundAvailable() { return .vnRemove }
        if CapabilityProbe.isVNForegroundInstanceMaskAvailable() { return .vnMask }
        return .saliency
    }

    private static func runForegroundInstanceMask(on image: CGImage, algoLabel: String) throws -> MaskedResult {
        guard #available(macOS 14, *) else {
            throw BgBgOneError.frameworkError("foreground-instance mask requires macOS 14+")
        }
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        let request = VNGenerateForegroundInstanceMaskRequest()
        do {
            try handler.perform([request])
        } catch {
            throw BgBgOneError.frameworkError("Vision foreground-mask request failed: \(error.localizedDescription)")
        }
        guard let result = request.results?.first else {
            throw BgBgOneError.noResult("no foreground subject detected")
        }

        // Generate the masked image (original with transparent background)
        let maskedPixelBuffer: CVPixelBuffer
        do {
            maskedPixelBuffer = try result.generateMaskedImage(
                ofInstances: result.allInstances,
                from: handler,
                croppedToInstancesExtent: false
            )
        } catch {
            throw BgBgOneError.frameworkError("Vision generateMaskedImage failed: \(error.localizedDescription)")
        }

        // Generate the raw mask too (single-channel) for downstream compositing
        let maskPixelBuffer: CVPixelBuffer
        do {
            maskPixelBuffer = try result.generateScaledMaskForImage(
                forInstances: result.allInstances,
                from: handler
            )
        } catch {
            throw BgBgOneError.frameworkError("Vision generateScaledMask failed: \(error.localizedDescription)")
        }

        let ciCtx = CIContext()
        let maskedCI = CIImage(cvPixelBuffer: maskedPixelBuffer)
        let maskCI = CIImage(cvPixelBuffer: maskPixelBuffer)
        guard let maskedCG = ciCtx.createCGImage(maskedCI, from: maskedCI.extent),
              let maskCG = ciCtx.createCGImage(maskCI, from: maskCI.extent) else {
            throw BgBgOneError.frameworkError("cannot convert mask to CGImage")
        }
        return MaskedResult(maskedImage: maskedCG, mask: maskCG, algoUsed: algoLabel)
    }

    private static func runForegroundInstanceMaskPerInstance(on image: CGImage, algoLabel: String) throws -> [MaskedResult] {
        guard #available(macOS 14, *) else {
            throw BgBgOneError.frameworkError("foreground-instance mask requires macOS 14+")
        }
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        let request = VNGenerateForegroundInstanceMaskRequest()
        do { try handler.perform([request]) } catch {
            throw BgBgOneError.frameworkError("Vision foreground-mask request failed: \(error.localizedDescription)")
        }
        guard let result = request.results?.first else {
            throw BgBgOneError.noResult("no foreground subject detected")
        }
        let ciCtx = CIContext()
        var outputs: [MaskedResult] = []
        for idx in result.allInstances {
            let oneInstance: IndexSet = [idx]
            let masked: CVPixelBuffer
            let maskOnly: CVPixelBuffer
            do {
                masked = try result.generateMaskedImage(ofInstances: oneInstance, from: handler, croppedToInstancesExtent: false)
                maskOnly = try result.generateScaledMaskForImage(forInstances: oneInstance, from: handler)
            } catch {
                throw BgBgOneError.frameworkError("per-instance mask generation failed at index \(idx): \(error.localizedDescription)")
            }
            let mCI = CIImage(cvPixelBuffer: masked)
            let kCI = CIImage(cvPixelBuffer: maskOnly)
            guard let mCG = ciCtx.createCGImage(mCI, from: mCI.extent),
                  let kCG = ciCtx.createCGImage(kCI, from: kCI.extent) else {
                throw BgBgOneError.frameworkError("cannot convert per-instance mask to CGImage")
            }
            outputs.append(MaskedResult(maskedImage: mCG, mask: kCG, algoUsed: algoLabel + "+multi"))
        }
        if outputs.isEmpty {
            throw BgBgOneError.noResult("no instances to emit")
        }
        return outputs
    }
}
