import Foundation
import CoreGraphics
import CoreImage
import ImageIO
import UniformTypeIdentifiers
import BgBgOneCore

enum BgBgOne {

    /// Run the pipeline for a single input. Returns one or more `RunResult`s.
    /// In default mode this is a single-element array; with `--multi`, one entry per detected
    /// instance.
    static func runMany(_ cfg: Config) throws -> [RunResult] {
        guard cfg.inputs.count == 1 else {
            throw BgBgOneError.userError(
                ErrorCodes.userInputCountMismatch,
                "BgBgOne.runMany expects exactly 1 input; got \(cfg.inputs.count).",
                context: ["got": String(cfg.inputs.count), "expected": "1"]
            )
        }
        if cfg.multiInstance && !cfg.maskOnly {
            return try runMultiInstance(cfg)
        }
        return [try run(cfg)]
    }

    private static func runMultiInstance(_ cfg: Config) throws -> [RunResult] {
        let input = cfg.inputs[0]
        let cgImage = try ImageLoader.load(input)
        let results = try ForegroundMask.maskedImages(from: cgImage, algo: cfg.algo)
        let baseStem = (((input as NSString).lastPathComponent) as NSString).deletingPathExtension
        var outputs: [RunResult] = []
        for (i, r) in results.enumerated() {
            var processedMask = try preparedMask(r.mask, cfg: cfg)
            let maskedImg = try MaskPostProcess.apply(mask: processedMask, to: cgImage)
            let positionedMasked = try ImageTransforms.position(maskedImg, scalePercent: cfg.scalePercent, position: cfg.position)
            processedMask = try ImageTransforms.position(processedMask, scalePercent: cfg.scalePercent, position: cfg.position)
            var final = try Compositor.compose(
                masked: positionedMasked,
                background: effectiveBackground(cfg),
                bgFit: cfg.bgFit,
                dropShadow: cfg.dropShadow,
                shadowOpacity: cfg.shadowOpacity
            )
            final = try cropIfNeeded(final, mask: processedMask, cfg: cfg)
            final = try ImageTransforms.downscaleIfNeeded(final, maxMegapixels: cfg.maxOutputMegapixels)
            let filename = InstanceNaming.expand(
                template: cfg.instanceNamingTemplate,
                base: baseStem,
                n: i + 1,
                ext: cfg.outputFormat.extensionForFile
            )
            var inst = cfg
            inst.inputs = [input]
            inst.output = nil
            inst.outputDir = nil
            // Multi-instance always writes files. Without --out-dir, write beside the input.
            let inputDir = (input as NSString).deletingLastPathComponent
            let outDir = cfg.outputDir ?? (inputDir.isEmpty ? "." : inputDir)
            inst.outputDir = nil
            inst.output = (outDir as NSString).appendingPathComponent(filename)
            let path = try Output.write(cgImage: final, cfg: inst, inputPath: input)
            outputs.append(RunResult(
                input: input,
                output: path,
                algo: r.algoUsed,
                format: cfg.outputFormat,
                width: final.width,
                height: final.height
            ))
        }
        return outputs
    }

    /// Single-result happy path (no --multi).
    static func run(_ cfg: Config) throws -> RunResult {
        guard cfg.inputs.count == 1 else {
            throw BgBgOneError.userError(
                ErrorCodes.userInputCountMismatch,
                "BgBgOne.run expects exactly 1 input; got \(cfg.inputs.count).",
                context: ["got": String(cfg.inputs.count), "expected": "1"]
            )
        }
        let input = cfg.inputs[0]

        let cgImage = try ImageLoader.load(input)

        // 1. produce a mask + masked image
        let maskedResult = try ForegroundMask.maskedImage(from: cgImage, algo: cfg.algo)

        // 1a. optional --mask-only short-circuit (emit the grayscale matte as the output)
        var processedMask = try preparedMask(maskedResult.mask, cfg: cfg)

        if cfg.maskOnly {
            processedMask = try ImageTransforms.position(processedMask, scalePercent: cfg.scalePercent, position: cfg.position)
            processedMask = try ImageTransforms.downscaleIfNeeded(processedMask, maxMegapixels: cfg.maxOutputMegapixels)
            let outputPath = try Output.write(cgImage: processedMask, cfg: cfg, inputPath: input)
            return RunResult(
                input: input,
                output: outputPath,
                algo: maskedResult.algoUsed + "+mask-only",
                format: cfg.outputFormat,
                width: processedMask.width,
                height: processedMask.height
            )
        }

        // 1ab. T57 #59 - reject alpha-producing filter chain when output is JPEG and
        // background is transparent (no opaque bg to flatten onto).
        if cfg.outputFormat == .jpeg, case .transparent = cfg.background {
            let alphaProducing = cfg.filters.contains { chain in
                chain.stages.contains { stage in
                    stage.calls.contains { call in
                        FilterRegistry.find(call.name)?.producesAlpha ?? false
                    }
                }
            }
            if alphaProducing {
                throw BgBgOneError.userError(
                    ErrorCodes.userJpegAlphaLoss,
                    "alpha-producing filter chain cannot output to JPEG (JPEG has no alpha channel)",
                    hint: "use PNG output (-o out.png / --to png) or add --bg color:white to flatten onto a solid background"
                )
            }
        }

        // 1b. Apply the matte as alpha. Feathering changes only this mask, not foreground RGB.
        // When cfg.filters is non-empty, take the LayeredImage path (T3) so per-layer
        // filters (fg:/bg:/all:/mask:) get a real layered surface to operate on.
        var final: CGImage
        if !cfg.filters.isEmpty {
            let canvas = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
            let bgRendered = try BackgroundRenderer.render(effectiveBackground(cfg), bgFit: cfg.bgFit, canvas: canvas)
            final = try FilterPipeline.executeAndFlatten(
                foreground: cgImage,
                mask: processedMask,
                background: bgRendered,
                canvas: canvas,
                chains: cfg.filters
            )
        } else {
            let maskedImg = try MaskPostProcess.apply(mask: processedMask, to: cgImage)
            let positionedMasked = try ImageTransforms.position(maskedImg, scalePercent: cfg.scalePercent, position: cfg.position)
            processedMask = try ImageTransforms.position(processedMask, scalePercent: cfg.scalePercent, position: cfg.position)
            // 2. compose with background (transparent = just emit the masked image)
            final = try Compositor.compose(
                masked: positionedMasked,
                background: effectiveBackground(cfg),
                bgFit: cfg.bgFit,
                dropShadow: cfg.dropShadow,
                shadowOpacity: cfg.shadowOpacity
            )
        }

        // 2a. optional --crop / --padding (tight-crop to subject bbox, then expand)
        final = try cropIfNeeded(final, mask: processedMask, cfg: cfg)
        final = try ImageTransforms.downscaleIfNeeded(final, maxMegapixels: cfg.maxOutputMegapixels)

        // 3. encode + write
        let outputPath = try Output.write(
            cgImage: final,
            cfg: cfg,
            inputPath: input
        )

        return RunResult(
            input: input,
            output: outputPath,
            algo: maskedResult.algoUsed,
            format: cfg.outputFormat,
            width: final.width,
            height: final.height
        )
    }

    private static func effectiveBackground(_ cfg: Config) -> Background {
        if case .transparent = cfg.background, !cfg.outputFormat.supportsTransparency {
            return .solidColor(RGBA(r: 1, g: 1, b: 1, a: 1))
        }
        return cfg.background
    }

    private static func preparedMask(_ mask: CGImage, cfg: Config) throws -> CGImage {
        var processed = try MaskPostProcess.process(mask: mask, threshold: cfg.threshold, feather: cfg.feather)
        if let roi = cfg.roi {
            processed = try MaskPostProcess.applyROI(roi, to: processed)
        }
        if !cfg.semitransparency {
            processed = try MaskPostProcess.thresholdMask(processed, threshold: cfg.threshold ?? 0.5)
        }
        return processed
    }

    private static func cropIfNeeded(_ image: CGImage, mask: CGImage, cfg: Config) throws -> CGImage {
        guard cfg.cropToSubject || cfg.padding != nil || cfg.cropMargins != nil else {
            return image
        }
        let subject = try MaskPostProcess.subjectBoundingBox(fromMask: mask)
        let imageSize = CGSize(width: image.width, height: image.height)
        let bbox: CGRect
        if let cropMargins = cfg.cropMargins {
            bbox = MaskPostProcess.paddedRect(subject, in: imageSize, margins: cropMargins)
        } else {
            bbox = MaskPostProcess.paddedRect(subject, in: imageSize, padding: cfg.padding, isPercent: cfg.paddingIsPercent)
        }
        return try MaskPostProcess.crop(image, to: bbox)
    }
}

struct RunResult: Sendable {
    let input: String
    let output: String        // "-" if stdout
    let algo: String
    let format: OutputFormat
    let width: Int
    let height: Int

    func toJSON() -> String {
        return """
        {"input":"\(JSONEscaper.escape(input))","output":"\(JSONEscaper.escape(output))","algo":"\(JSONEscaper.escape(algo))","format":"\(format.rawValue)","width":\(width),"height":\(height)}
        """
    }
}
