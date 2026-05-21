import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import BgBgOneCore

enum Output {

    /// Encode the final CGImage in the configured format and write to either `cfg.output`,
    /// `cfg.outputDir` (with an auto-derived filename), or stdout. Returns the path or "-".
    static func write(cgImage: CGImage, cfg: Config, inputPath: String) throws -> String {
        let format = cfg.outputFormat
        let utType = try format.imageIOType()
        let opts: [CFString: Any] = {
            var d: [CFString: Any] = [:]
            switch format {
            case .jpeg, .heic, .avif:
                d[kCGImageDestinationLossyCompressionQuality] = CGFloat(cfg.quality) / 100.0
            case .png, .tiff:
                break
            }
            return d
        }()

        // Resolve destination
        if let outPath = cfg.output {
            try writeToFile(cgImage: cgImage, path: outPath, utType: utType, opts: opts)
            return outPath
        }
        if let outDir = cfg.outputDir {
            let outPath = try deriveBatchPath(inputPath: inputPath, outDir: outDir, format: format)
            try writeToFile(cgImage: cgImage, path: outPath, utType: utType, opts: opts)
            return outPath
        }
        if cfg.autoFileOutput {
            guard let outPath = OutputNaming.defaultOutputPath(inputPath: inputPath, format: format) else {
                throw BgBgOneError.userError("cannot derive an output filename for stdin; use -o <file> or --out-dir <dir>")
            }
            try writeToFile(cgImage: cgImage, path: outPath, utType: utType, opts: opts)
            return outPath
        }
        // stdout
        try writeToStdout(cgImage: cgImage, utType: utType, opts: opts)
        return "-"
    }

    private static func writeToFile(cgImage: CGImage, path: String, utType: UTType, opts: [CFString: Any]) throws {
        let url = URL(fileURLWithPath: path)
        let parent = url.deletingLastPathComponent()
        let fm = FileManager.default
        var isDirectory = ObjCBool(false)
        if fm.fileExists(atPath: parent.path, isDirectory: &isDirectory) {
            guard isDirectory.boolValue else {
                throw BgBgOneError.userError("output parent is not a directory: \(parent.path)")
            }
        } else {
            do {
                try fm.createDirectory(at: parent, withIntermediateDirectories: true)
            } catch {
                throw BgBgOneError.userError("cannot create output parent directory \(parent.path): \(error.localizedDescription)")
            }
        }
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, utType.identifier as CFString, 1, nil) else {
            throw BgBgOneError.frameworkError("cannot create output destination at \(path) (format \(utType.identifier) may be unsupported)")
        }
        CGImageDestinationAddImage(dest, cgImage, opts as CFDictionary)
        guard CGImageDestinationFinalize(dest) else {
            throw BgBgOneError.frameworkError("encoding/writing failed at \(path)")
        }
    }

    private static func writeToStdout(cgImage: CGImage, utType: UTType, opts: [CFString: Any]) throws {
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, utType.identifier as CFString, 1, nil) else {
            throw BgBgOneError.frameworkError("cannot create output destination for stdout (format \(utType.identifier) may be unsupported)")
        }
        CGImageDestinationAddImage(dest, cgImage, opts as CFDictionary)
        guard CGImageDestinationFinalize(dest) else {
            throw BgBgOneError.frameworkError("encoding failed for stdout")
        }
        FileHandle.standardOutput.write(data as Data)
    }

    private static func deriveBatchPath(inputPath: String, outDir: String, format: OutputFormat) throws -> String {
        guard let path = OutputNaming.batchOutputPath(inputPath: inputPath, outDir: outDir, format: format) else {
            throw BgBgOneError.userError("cannot derive an output filename for stdin; use -o <file>")
        }
        return path
    }
}

extension OutputFormat {
    func imageIOType() throws -> UTType {
        switch self {
        case .png:  return .png
        case .jpeg: return .jpeg
        case .heic: return .heic
        case .avif:
            guard let type = UTType(filenameExtension: "avif") else {
                throw BgBgOneError.frameworkError("AVIF output is unavailable on this macOS SDK")
            }
            return type
        case .tiff: return .tiff
        }
    }
}
