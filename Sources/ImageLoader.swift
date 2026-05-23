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
                throw BgBgOneError.userError(
                    ErrorCodes.userStdinEmpty,
                    "no image data on stdin",
                    origin: "stdin"
                )
            }
        } else {
            let url = URL(fileURLWithPath: path)
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw BgBgOneError.userError(
                    ErrorCodes.userInputNotFound,
                    "input not found: \(path)",
                    origin: path,
                    context: ["path": path]
                )
            }
            do {
                data = try Data(contentsOf: url)
            } catch {
                throw BgBgOneError.userError(
                    ErrorCodes.userImageReadFail,
                    "cannot read \(path): \(error.localizedDescription)",
                    origin: path,
                    context: ["path": path]
                )
            }
        }
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw BgBgOneError.userError(
                ErrorCodes.userImageDecodeFail,
                "cannot decode image: \(path)",
                origin: path,
                context: ["path": path]
            )
        }
        guard let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
            throw BgBgOneError.userError(
                ErrorCodes.userImageDecodeFail,
                "cannot decode image: \(path)",
                origin: path,
                context: ["path": path]
            )
        }
        return img
    }
}
