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
        if format == .zip {
            let data = try zipData(from: cgImage, quality: cfg.quality)
            return try writeData(data, cfg: cfg, inputPath: inputPath, format: format)
        }
        let utType = try format.imageIOType()
        let opts: [CFString: Any] = {
            var d: [CFString: Any] = [:]
            switch format {
            case .jpeg, .heic, .avif:
                d[kCGImageDestinationLossyCompressionQuality] = CGFloat(cfg.quality) / 100.0
            case .png, .zip, .tiff:
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

    private static func writeData(_ data: Data, cfg: Config, inputPath: String, format: OutputFormat) throws -> String {
        if let outPath = cfg.output {
            try writeDataToFile(data, path: outPath)
            return outPath
        }
        if let outDir = cfg.outputDir {
            let outPath = try deriveBatchPath(inputPath: inputPath, outDir: outDir, format: format)
            try writeDataToFile(data, path: outPath)
            return outPath
        }
        if cfg.autoFileOutput {
            guard let outPath = OutputNaming.defaultOutputPath(inputPath: inputPath, format: format) else {
                throw BgBgOneError.userError("cannot derive an output filename for stdin; use -o <file> or --out-dir <dir>")
            }
            try writeDataToFile(data, path: outPath)
            return outPath
        }
        FileHandle.standardOutput.write(data)
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

    private static func writeDataToFile(_ data: Data, path: String) throws {
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
        try data.write(to: url, options: .atomic)
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
        case .zip:
            throw BgBgOneError.frameworkError("zip output is a package, not an ImageIO image type")
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

private extension Output {
    static func zipData(from image: CGImage, quality: Int) throws -> Data {
        let color = try flattenedJPEGData(from: image, quality: quality)
        let alpha = try alphaPNGData(from: image)
        return StoredZipArchive(files: [
            StoredZipArchive.File(name: "color.jpg", data: color),
            StoredZipArchive.File(name: "alpha.png", data: alpha),
        ]).data()
    }

    static func flattenedJPEGData(from image: CGImage, quality: Int) throws -> Data {
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: cs,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            throw BgBgOneError.frameworkError("cannot create zip color image context")
        }
        let rect = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        ctx.fill(rect)
        ctx.draw(image, in: rect)
        guard let out = ctx.makeImage() else {
            throw BgBgOneError.frameworkError("cannot create zip color image")
        }
        return try encodeImageData(out, type: .jpeg, options: [
            kCGImageDestinationLossyCompressionQuality: CGFloat(quality) / 100.0
        ])
    }

    static func alphaPNGData(from image: CGImage) throws -> Data {
        let w = image.width
        let h = image.height
        var rgba = [UInt8](repeating: 0, count: w * h * 4)
        let cs = CGColorSpaceCreateDeviceRGB()
        try rgba.withUnsafeMutableBytes { raw in
            guard let base = raw.baseAddress,
                  let ctx = CGContext(
                    data: base,
                    width: w,
                    height: h,
                    bitsPerComponent: 8,
                    bytesPerRow: w * 4,
                    space: cs,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                  ) else {
                throw BgBgOneError.frameworkError("cannot create zip alpha extraction context")
            }
            ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        }

        var alpha = [UInt8](repeating: 0, count: w * h)
        for i in 0..<(w * h) {
            alpha[i] = rgba[i * 4 + 3]
        }
        let provider = CGDataProvider(data: Data(alpha) as CFData)
        let gray = CGColorSpaceCreateDeviceGray()
        guard let provider,
              let mask = CGImage(
                width: w,
                height: h,
                bitsPerComponent: 8,
                bitsPerPixel: 8,
                bytesPerRow: w,
                space: gray,
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              ) else {
            throw BgBgOneError.frameworkError("cannot create zip alpha image")
        }
        return try encodeImageData(mask, type: .png, options: [:])
    }

    static func encodeImageData(_ image: CGImage, type: UTType, options: [CFString: Any]) throws -> Data {
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, type.identifier as CFString, 1, nil) else {
            throw BgBgOneError.frameworkError("cannot create image encoder for \(type.identifier)")
        }
        CGImageDestinationAddImage(dest, image, options as CFDictionary)
        guard CGImageDestinationFinalize(dest) else {
            throw BgBgOneError.frameworkError("cannot encode image data")
        }
        return data as Data
    }
}

private struct StoredZipArchive {
    struct File {
        let name: String
        let data: Data
    }

    let files: [File]

    func data() -> Data {
        var out = Data()
        var central = Data()
        for file in files {
            let localOffset = UInt32(out.count)
            let nameData = Data(file.name.utf8)
            let crc = CRC32.checksum(file.data)
            appendLocalHeader(to: &out, name: nameData, crc: crc, size: UInt32(file.data.count))
            out.append(file.data)
            appendCentralHeader(to: &central, name: nameData, crc: crc, size: UInt32(file.data.count), localOffset: localOffset)
        }
        let centralOffset = UInt32(out.count)
        out.append(central)
        appendEnd(to: &out, fileCount: UInt16(files.count), centralSize: UInt32(central.count), centralOffset: centralOffset)
        return out
    }

    private func appendLocalHeader(to data: inout Data, name: Data, crc: UInt32, size: UInt32) {
        data.appendLE32(0x04034b50)
        data.appendLE16(20)
        data.appendLE16(0)
        data.appendLE16(0)
        data.appendLE16(0)
        data.appendLE16(0)
        data.appendLE32(crc)
        data.appendLE32(size)
        data.appendLE32(size)
        data.appendLE16(UInt16(name.count))
        data.appendLE16(0)
        data.append(name)
    }

    private func appendCentralHeader(to data: inout Data, name: Data, crc: UInt32, size: UInt32, localOffset: UInt32) {
        data.appendLE32(0x02014b50)
        data.appendLE16(20)
        data.appendLE16(20)
        data.appendLE16(0)
        data.appendLE16(0)
        data.appendLE16(0)
        data.appendLE16(0)
        data.appendLE32(crc)
        data.appendLE32(size)
        data.appendLE32(size)
        data.appendLE16(UInt16(name.count))
        data.appendLE16(0)
        data.appendLE16(0)
        data.appendLE16(0)
        data.appendLE16(0)
        data.appendLE32(0)
        data.appendLE32(localOffset)
        data.append(name)
    }

    private func appendEnd(to data: inout Data, fileCount: UInt16, centralSize: UInt32, centralOffset: UInt32) {
        data.appendLE32(0x06054b50)
        data.appendLE16(0)
        data.appendLE16(0)
        data.appendLE16(fileCount)
        data.appendLE16(fileCount)
        data.appendLE32(centralSize)
        data.appendLE32(centralOffset)
        data.appendLE16(0)
    }
}

private enum CRC32 {
    private static let table: [UInt32] = (0..<256).map { i in
        var c = UInt32(i)
        for _ in 0..<8 {
            c = (c & 1) == 1 ? 0xedb88320 ^ (c >> 1) : c >> 1
        }
        return c
    }

    static func checksum(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xffffffff
        for byte in data {
            crc = table[Int((crc ^ UInt32(byte)) & 0xff)] ^ (crc >> 8)
        }
        return crc ^ 0xffffffff
    }
}

private extension Data {
    mutating func appendLE16(_ value: UInt16) {
        append(UInt8(value & 0xff))
        append(UInt8((value >> 8) & 0xff))
    }

    mutating func appendLE32(_ value: UInt32) {
        append(UInt8(value & 0xff))
        append(UInt8((value >> 8) & 0xff))
        append(UInt8((value >> 16) & 0xff))
        append(UInt8((value >> 24) & 0xff))
    }
}
