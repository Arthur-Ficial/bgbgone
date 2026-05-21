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
            var maskedImg = r.maskedImage
            if cfg.feather > 0.001 {
                maskedImg = MaskPostProcess.feather(maskedImg, radius: cfg.feather)
            }
            var final = try Compositor.compose(
                masked: maskedImg,
                mask: r.mask,
                background: cfg.background,
                bgFit: cfg.bgFit,
                originalSize: CGSize(width: cgImage.width, height: cgImage.height)
            )
            if cfg.cropToSubject {
                let bbox = MaskPostProcess.subjectBoundingBox(r.maskedImage)
                final = MaskPostProcess.crop(final, to: bbox)
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
            // Decide where to write this instance:
            //  - If user set --out-dir, write under there with the expanded filename.
            //  - Else if user set -o <file>, ignore -o (multi can't go to a single file)
            //  - Else write next to the input file.
            let outDir: String
            if let d = cfg.outputDir {
                outDir = d
            } else if cfg.output != nil {
                outDir = (input as NSString).deletingLastPathComponent
            } else {
                outDir = "."
            }
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
        if cfg.maskOnly {
            let outputPath = try Output.write(cgImage: maskedResult.mask, cfg: cfg, inputPath: input)
            return RunResult(
                input: input,
                output: outputPath,
                algo: maskedResult.algoUsed + "+mask-only",
                format: cfg.outputFormat,
                width: maskedResult.mask.width,
                height: maskedResult.mask.height
            )
        }

        // 1b. optional --feather (Gaussian blur on the masked image so edges soften)
        var maskedImg = maskedResult.maskedImage
        if cfg.feather > 0.001 {
            maskedImg = MaskPostProcess.feather(maskedImg, radius: cfg.feather)
        }

        // 2. compose with background (transparent = just emit the masked image)
        var final = try Compositor.compose(
            masked: maskedImg,
            mask: maskedResult.mask,
            background: cfg.background,
            bgFit: cfg.bgFit,
            originalSize: CGSize(width: cgImage.width, height: cgImage.height)
        )

        // 2a. optional --crop (tight-crop to subject bbox)
        if cfg.cropToSubject {
            let bbox = MaskPostProcess.subjectBoundingBox(maskedResult.maskedImage)
            final = MaskPostProcess.crop(final, to: bbox)
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
}

struct RunResult {
    let input: String
    let output: String        // "-" if stdout
    let algo: String
    let format: OutputFormat
    let width: Int
    let height: Int

    func toJSON() -> String {
        // Hand-rolled to avoid Foundation JSONEncoder ordering ambiguity. Keys quoted, values JSON-escaped where needed.
        func esc(_ s: String) -> String {
            var out = ""
            for c in s {
                switch c {
                case "\"": out += "\\\""
                case "\\": out += "\\\\"
                case "\n": out += "\\n"
                case "\t": out += "\\t"
                default: out.append(c)
                }
            }
            return out
        }
        return """
        {"input":"\(esc(input))","output":"\(esc(output))","algo":"\(algo)","format":"\(format.rawValue)","width":\(width),"height":\(height)}
        """
    }
}
