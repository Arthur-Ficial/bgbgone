import Foundation
import CoreGraphics
import CoreImage
import CoreVideo
import Vision
import BgBgOneCore

struct MaskedResult {
    /// The alpha mask itself (grayscale). Consumers post-process and apply it
    /// themselves; we deliberately do NOT pre-compute a masked image here
    /// because every caller re-applies the mask after `preparedMask`
    /// (threshold, ROI, feather), so any pre-computed masked image would be
    /// thrown away.
    let mask: CGImage
    /// Which algorithm actually ran (after `auto` resolution).
    let algoUsed: String
}

enum ForegroundMask {
    private static let ciContext = CIContext(options: [.cacheIntermediates: false])

    /// Apply the chosen (or auto-picked) algorithm and return the masked image + mask.
    static func maskedImage(from image: CGImage, algo: Algo) throws -> MaskedResult {
        let resolved = resolve(algo)
        switch resolved {
        case .auto:
            return try runForegroundInstanceMask(on: image, algoLabel: Algo.vnMask.rawValue)
        case .vnMask:
            return try runForegroundInstanceMask(on: image, algoLabel: resolved.rawValue)
        case .person:
            return try runPersonSegmentation(on: image)
        case .saliency:
            return try runObjectnessSaliency(on: image)
        }
    }

    /// Same as `maskedImage(from:algo:)` but returns one MaskedResult per detected instance.
    static func maskedImages(from image: CGImage, algo: Algo) throws -> [MaskedResult] {
        let resolved = resolve(algo)
        switch resolved {
        case .auto, .vnMask:
            return try runForegroundInstanceMaskPerInstance(on: image, algoLabel: Algo.vnMask.rawValue)
        case .person, .saliency:
            return [try maskedImage(from: image, algo: resolved)]
        }
    }

    private static func resolve(_ algo: Algo) -> Algo {
        if algo != .auto { return algo }
        return .vnMask
    }

    private static func runForegroundInstanceMask(on image: CGImage, algoLabel: String) throws -> MaskedResult {
        guard #available(macOS 14, *) else {
            throw BgBgOneError.frameworkError(
                ErrorCodes.frameworkVisionFail,
                "foreground-instance mask requires macOS 14+",
                hint: "upgrade macOS or use --type person/saliency"
            )
        }
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        let request = VNGenerateForegroundInstanceMaskRequest()
        do {
            try handler.perform([request])
        } catch {
            throw BgBgOneError.frameworkError(
                ErrorCodes.frameworkVisionFail,
                "Vision foreground-mask request failed: \(error.localizedDescription)"
            )
        }
        guard let result = request.results?.first else {
            throw BgBgOneError.noResult(
                ErrorCodes.noResultNoSubject,
                "no foreground subject detected",
                hint: "try --type person for portraits or --type saliency for arbitrary subjects"
            )
        }

        let maskPixelBuffer: CVPixelBuffer
        do {
            maskPixelBuffer = try result.generateScaledMaskForImage(
                forInstances: result.allInstances,
                from: handler
            )
        } catch {
            throw BgBgOneError.frameworkError(
                ErrorCodes.frameworkVisionNoMask,
                "Vision generateScaledMask failed: \(error.localizedDescription)"
            )
        }
        return try resultFromMaskPixelBuffer(maskPixelBuffer, source: image, algoLabel: algoLabel)
    }

    private static func runForegroundInstanceMaskPerInstance(on image: CGImage, algoLabel: String) throws -> [MaskedResult] {
        guard #available(macOS 14, *) else {
            throw BgBgOneError.frameworkError(
                ErrorCodes.frameworkVisionFail,
                "foreground-instance mask requires macOS 14+",
                hint: "upgrade macOS or use --type person/saliency"
            )
        }
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        let request = VNGenerateForegroundInstanceMaskRequest()
        do {
            try handler.perform([request])
        } catch {
            throw BgBgOneError.frameworkError(
                ErrorCodes.frameworkVisionFail,
                "Vision foreground-mask request failed: \(error.localizedDescription)"
            )
        }
        guard let result = request.results?.first else {
            throw BgBgOneError.noResult(
                ErrorCodes.noResultNoSubject,
                "no foreground subject detected",
                hint: "try --type person for portraits or --type saliency for arbitrary subjects"
            )
        }

        var outputs: [MaskedResult] = []
        for idx in result.allInstances {
            let oneInstance: IndexSet = [idx]
            let maskOnly: CVPixelBuffer
            do {
                maskOnly = try result.generateScaledMaskForImage(forInstances: oneInstance, from: handler)
            } catch {
                throw BgBgOneError.frameworkError(
                    ErrorCodes.frameworkVisionNoMask,
                    "per-instance mask generation failed at index \(idx): \(error.localizedDescription)",
                    context: ["index": String(idx)]
                )
            }
            outputs.append(try resultFromMaskPixelBuffer(maskOnly, source: image, algoLabel: algoLabel + "+multi"))
        }
        if outputs.isEmpty {
            throw BgBgOneError.noResult(
                ErrorCodes.noResultNoSubject,
                "no instances to emit"
            )
        }
        return outputs
    }

    private static func runPersonSegmentation(on image: CGImage) throws -> MaskedResult {
        guard #available(macOS 12, *) else {
            throw BgBgOneError.frameworkError(
                ErrorCodes.frameworkVisionFail,
                "person segmentation requires macOS 12+"
            )
        }
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .accurate
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        do {
            try handler.perform([request])
        } catch {
            throw BgBgOneError.frameworkError(
                ErrorCodes.frameworkVisionFail,
                "Vision person-segmentation request failed: \(error.localizedDescription)"
            )
        }
        guard let result = request.results?.first else {
            throw BgBgOneError.noResult(
                ErrorCodes.noResultNoSubject,
                "no person detected",
                hint: "try --type vn-mask or --type saliency"
            )
        }
        return try resultFromMaskPixelBuffer(result.pixelBuffer, source: image, algoLabel: Algo.person.rawValue)
    }

    private static func runObjectnessSaliency(on image: CGImage) throws -> MaskedResult {
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        let request = VNGenerateObjectnessBasedSaliencyImageRequest()
        do {
            try handler.perform([request])
        } catch {
            throw BgBgOneError.frameworkError(
                ErrorCodes.frameworkVisionFail,
                "Vision saliency request failed: \(error.localizedDescription)"
            )
        }
        guard let result = request.results?.first else {
            throw BgBgOneError.noResult(
                ErrorCodes.noResultNoSubject,
                "no salient object detected"
            )
        }
        return try resultFromMaskPixelBuffer(result.pixelBuffer, source: image, algoLabel: Algo.saliency.rawValue)
    }

    /// Convert the Vision pixel-buffer mask into a CGImage at the SOURCE
    /// image's resolution. Vision requests routinely return masks at a
    /// downsampled resolution (e.g. 2016x1512 for a 3781x2389 source);
    /// every downstream consumer (FilterPipeline, MaskPostProcess, ROI,
    /// bounding box, `--channels alpha`) assumes the mask shares the
    /// source's coordinate space, so we resample here at the boundary.
    /// Doing it here means there is exactly one place that owns mask
    /// resolution, and every later step gets a mask in lock-step with
    /// the foreground/background extent without further patching.
    private static func resultFromMaskPixelBuffer(
        _ pixelBuffer: CVPixelBuffer,
        source: CGImage,
        algoLabel: String
    ) throws -> MaskedResult {
        let maskCI = CIImage(cvPixelBuffer: pixelBuffer)
        let targetW = source.width
        let targetH = source.height
        let maskCI2: CIImage
        if Int(maskCI.extent.width.rounded()) == targetW && Int(maskCI.extent.height.rounded()) == targetH {
            maskCI2 = maskCI
        } else {
            let sx = CGFloat(targetW) / maskCI.extent.width
            let sy = CGFloat(targetH) / maskCI.extent.height
            maskCI2 = maskCI
                .transformed(by: CGAffineTransform(scaleX: sx, y: sy))
                .cropped(to: CGRect(x: 0, y: 0, width: targetW, height: targetH))
        }
        guard let maskCG = ciContext.createCGImage(
            maskCI2,
            from: CGRect(x: 0, y: 0, width: targetW, height: targetH)
        ) else {
            throw BgBgOneError.frameworkError(
                ErrorCodes.frameworkCGImageFail,
                "cannot convert mask to CGImage"
            )
        }
        return MaskedResult(mask: maskCG, algoUsed: algoLabel)
    }
}
