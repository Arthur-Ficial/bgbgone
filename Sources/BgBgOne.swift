import Foundation
import CoreGraphics
import CoreImage
import ImageIO
import UniformTypeIdentifiers
import BgBgOneCore

@MainActor
enum BgBgOne {

    /// Run the pipeline for a single input. Returns one or more `RunResult`s.
    /// In default mode this is a single-element array; with `--multi`, one entry per detected
    /// instance.
    static func runMany(_ cfg: Config) throws -> [RunResult] {
        guard cfg.inputs.count == 1 else {
            throw BgBgOneError.userError("BgBgOne.runMany expects exactly 1 input; got \(cfg.inputs.count).")
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
            let processedMask = try MaskPostProcess.process(mask: r.mask, threshold: cfg.threshold, feather: cfg.feather)
            let maskedImg = try MaskPostProcess.apply(mask: processedMask, to: cgImage)
            var final = try Compositor.compose(
                masked: maskedImg,
                background: effectiveBackground(cfg),
                bgFit: cfg.bgFit,
                dropShadow: cfg.dropShadow
            )
            if cfg.cropToSubject || cfg.padding != nil {
                let bbox = MaskPostProcess.paddedRect(
                    try MaskPostProcess.subjectBoundingBox(fromMask: processedMask),
                    in: CGSize(width: final.width, height: final.height),
                    padding: cfg.padding,
                    isPercent: cfg.paddingIsPercent
                )
                final = try MaskPostProcess.crop(final, to: bbox)
            }
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
            throw BgBgOneError.userError("BgBgOne.run expects exactly 1 input; got \(cfg.inputs.count).")
        }
        let input = cfg.inputs[0]

        let cgImage = try ImageLoader.load(input)

        // 1. produce a mask + masked image
        let maskedResult = try ForegroundMask.maskedImage(from: cgImage, algo: cfg.algo)

        // 1a. optional --mask-only short-circuit (emit the grayscale matte as the output)
        let processedMask = try MaskPostProcess.process(mask: maskedResult.mask, threshold: cfg.threshold, feather: cfg.feather)

        if cfg.maskOnly {
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

        // 1b. Apply the matte as alpha. Feathering changes only this mask, not foreground RGB.
        let maskedImg = try MaskPostProcess.apply(mask: processedMask, to: cgImage)

        // 2. compose with background (transparent = just emit the masked image)
        var final = try Compositor.compose(
            masked: maskedImg,
            background: effectiveBackground(cfg),
            bgFit: cfg.bgFit,
            dropShadow: cfg.dropShadow
        )

        // 2a. optional --crop / --padding (tight-crop to subject bbox, then expand)
        if cfg.cropToSubject || cfg.padding != nil {
            let bbox = MaskPostProcess.paddedRect(
                try MaskPostProcess.subjectBoundingBox(fromMask: processedMask),
                in: CGSize(width: final.width, height: final.height),
                padding: cfg.padding,
                isPercent: cfg.paddingIsPercent
            )
            final = try MaskPostProcess.crop(final, to: bbox)
        }

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
}

struct RunResult {
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
