import Foundation

public enum OutputNaming {
    public static func defaultOutputPath(inputPath: String, format: OutputFormat) -> String? {
        guard inputPath != "-" else { return nil }

        let base = (inputPath as NSString).lastPathComponent
        guard !base.isEmpty else { return nil }

        let dir = (inputPath as NSString).deletingLastPathComponent
        let stem = (base as NSString).deletingPathExtension
        let filename = "\(stem)_bgbgone.\(format.extensionForFile)"
        if dir.isEmpty {
            return filename
        }
        return (dir as NSString).appendingPathComponent(filename)
    }
}

public extension OutputFormat {
    static func parse(_ raw: String) -> OutputFormat? {
        switch raw.lowercased() {
        case "png": return .png
        case "jpg", "jpeg": return .jpeg
        case "webp": return .webp
        case "heic", "heif": return .heic
        case "avif": return .avif
        case "tif", "tiff": return .tiff
        default: return nil
        }
    }

    static func fromFileExtension(_ path: String) -> OutputFormat? {
        let ext = (path as NSString).pathExtension
        guard !ext.isEmpty else { return nil }
        return parse(ext)
    }

    var extensionForFile: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        case .webp: return "webp"
        case .heic: return "heic"
        case .avif: return "avif"
        case .tiff: return "tiff"
        }
    }

    var supportsTransparency: Bool {
        switch self {
        case .jpeg:
            return false
        case .png, .webp, .heic, .avif, .tiff:
            return true
        }
    }
}
