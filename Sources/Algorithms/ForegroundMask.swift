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

        let maskPixelBuffer: CVPixelBuffer
        do {
            maskPixelBuffer = try result.generateScaledMaskForImage(
                forInstances: result.allInstances,
                from: handler
            )
        } catch {
            throw BgBgOneError.frameworkError("Vision generateScaledMask failed: \(error.localizedDescription)")
        }
        return try resultFromMaskPixelBuffer(maskPixelBuffer, algoLabel: algoLabel)
    }

    private static func runForegroundInstanceMaskPerInstance(on image: CGImage, algoLabel: String) throws -> [MaskedResult] {
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

        var outputs: [MaskedResult] = []
        for idx in result.allInstances {
            let oneInstance: IndexSet = [idx]
            let maskOnly: CVPixelBuffer
            do {
                maskOnly = try result.generateScaledMaskForImage(forInstances: oneInstance, from: handler)
            } catch {
                throw BgBgOneError.frameworkError("per-instance mask generation failed at index \(idx): \(error.localizedDescription)")
            }
            outputs.append(try resultFromMaskPixelBuffer(maskOnly, algoLabel: algoLabel + "+multi"))
        }
        if outputs.isEmpty {
            throw BgBgOneError.noResult("no instances to emit")
        }
        return outputs
    }

    private static func runPersonSegmentation(on image: CGImage) throws -> MaskedResult {
        guard #available(macOS 12, *) else {
            throw BgBgOneError.frameworkError("person segmentation requires macOS 12+")
        }
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .accurate
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        do {
            try handler.perform([request])
        } catch {
            throw BgBgOneError.frameworkError("Vision person-segmentation request failed: \(error.localizedDescription)")
        }
        guard let result = request.results?.first else {
            throw BgBgOneError.noResult("no person detected")
        }
        return try resultFromMaskPixelBuffer(result.pixelBuffer, algoLabel: Algo.person.rawValue)
    }

    private static func runObjectnessSaliency(on image: CGImage) throws -> MaskedResult {
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        let request = VNGenerateObjectnessBasedSaliencyImageRequest()
        do {
            try handler.perform([request])
        } catch {
            throw BgBgOneError.frameworkError("Vision saliency request failed: \(error.localizedDescription)")
        }
        guard let result = request.results?.first else {
            throw BgBgOneError.noResult("no salient object detected")
        }
        return try resultFromMaskPixelBuffer(result.pixelBuffer, algoLabel: Algo.saliency.rawValue)
    }

    private static func resultFromMaskPixelBuffer(
        _ pixelBuffer: CVPixelBuffer,
        algoLabel: String
    ) throws -> MaskedResult {
        let maskCI = CIImage(cvPixelBuffer: pixelBuffer)
        guard let maskCG = ciContext.createCGImage(maskCI, from: maskCI.extent) else {
            throw BgBgOneError.frameworkError("cannot convert mask to CGImage")
        }
        return MaskedResult(mask: maskCG, algoUsed: algoLabel)
    }
}
