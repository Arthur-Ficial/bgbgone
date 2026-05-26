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
            let processedMask = try preparedMask(r.mask, cfg: cfg)
            let maskedImg = try MaskPostProcess.apply(mask: processedMask, to: cgImage)
            var final = try Compositor.compose(
                masked: maskedImg,
                background: effectiveBackground(cfg, input: input),
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

        // 1a. optional --channels alpha short-circuit (emit the grayscale matte)
        var processedMask = try preparedMask(maskedResult.mask, cfg: cfg)

        if cfg.maskOnly {
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
                    hint: "use PNG output (-o out.png / --format png) or add --bg color:white to flatten onto a solid background"
                )
            }
        }

        // 1b. Apply the matte as alpha. Feathering changes only this mask, not foreground RGB.
        // When cfg.filters is non-empty, take the LayeredImage path (T3) so per-layer
        // filters (fg:/bg:/all:/mask:) get a real layered surface to operate on.
        var final: CGImage
        if !cfg.filters.isEmpty {
            let canvas = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
            let bgRendered = try BackgroundRenderer.render(effectiveBackground(cfg, input: input), bgFit: cfg.bgFit, canvas: canvas)
            final = try FilterPipeline.executeAndFlatten(
                foreground: cgImage,
                mask: processedMask,
                background: bgRendered,
                canvas: canvas,
                chains: cfg.filters
            )
        } else {
            let maskedImg = try MaskPostProcess.apply(mask: processedMask, to: cgImage)
            // 2. compose with background (transparent = just emit the masked image)
            final = try Compositor.compose(
                masked: maskedImg,
                background: effectiveBackground(cfg, input: input),
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

    private static func effectiveBackground(_ cfg: Config, input: String? = nil) -> Background {
        // Auto-promote source-as-bg ONLY when the output format cannot hold
        // alpha. For transparent-capable formats (PNG, etc.) leave the
        // background transparent so that filters like fg:outline / fg:shadow
        // / fg:glow produce a true cut-out sticker against an alpha channel,
        // not against the original photo. This is the one-pass invariant:
        //   bgbgone in.jpg --filter "fg:outline=..." -o out.png  → transparent
        //   bgbgone in.jpg --filter "fg:sepia=..."    -o out.jpg → source as bg
        if case .transparent = cfg.background,
           filtersTouchSourceBackground(cfg.filters),
           !cfg.outputFormat.supportsTransparency,
           let input,
           input != "-" {
            return .image(input)
        }
        if case .transparent = cfg.background, !cfg.outputFormat.supportsTransparency {
            return .solidColor(RGBA(r: 1, g: 1, b: 1, a: 1))
        }
        return cfg.background
    }

    private static func filtersTouchSourceBackground(_ chains: [FilterChain]) -> Bool {
        chains.contains { chain in
            chain.stages.contains { stage in
                stage.layer == .bg || stage.layer == .all || stage.layer == .fg
            }
        }
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
        guard cfg.cropToSubject || cfg.cropMargins != nil else {
            return image
        }
        let subject = try MaskPostProcess.subjectBoundingBox(fromMask: mask)
        let imageSize = CGSize(width: image.width, height: image.height)
        let bbox = MaskPostProcess.paddedRect(subject, in: imageSize, margins: cfg.cropMargins)
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

    func toJSON(filters: [FilterChain], outputOverride: String? = nil, imageBase64: String? = nil) -> String {
        let filterValues = filters
            .map { "\"\(JSONEscaper.escape($0.normalizedString))\"" }
            .joined(separator: ",")
        let renderedOutput = outputOverride ?? output
        let imageField = imageBase64.map { ",\"image_b64\":\"\(JSONEscaper.escape($0))\"" } ?? ""
        return """
        {"ok":true,"schema":"bgbgone.run.v\(CLIContract.jsonSchemaVersion)","result":{"input":"\(JSONEscaper.escape(input))","output":"\(JSONEscaper.escape(renderedOutput))","algo":"\(JSONEscaper.escape(algo))","format":"\(format.rawValue)","width":\(width),"height":\(height),"filters":[\(filterValues)]\(imageField)}}
        """
    }
}
