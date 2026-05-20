import Foundation
import CoreGraphics
import ImageIO
import BgBgOneCore

enum ImageLoader {
    /// Load a CGImage from a file path, or stdin (path = "-").
    static func load(_ path: String) throws -> CGImage {
        let data: Data
        if path == "-" {
            data = FileHandle.standardInput.readDataToEndOfFile()
            guard !data.isEmpty else {
                throw BgBgOneError.userError("no image data on stdin")
            }
        } else {
            let url = URL(fileURLWithPath: path)
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw BgBgOneError.userError("input not found: \(path)")
            }
            do {
                data = try Data(contentsOf: url)
            } catch {
                throw BgBgOneError.userError("cannot read \(path): \(error.localizedDescription)")
            }
        }
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw BgBgOneError.userError("cannot decode image: \(path)")
        }
        guard let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
            throw BgBgOneError.userError("cannot decode image: \(path)")
        }
        return img
    }
}
