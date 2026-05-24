import Foundation

/// Shared CLI/server contract values that appear in parser validation, help,
/// docs linting, and generated documentation. Behavioural value lists belong
/// here first; call sites should format these lists instead of retyping them.
public enum CLIContract {
    public static let toolName = "bgbgone"

    public static let outputFormats = ["png", "jpg", "zip", "heic", "avif", "tiff"]
    /// Internal Algo enum raw values. Not directly exposed on the CLI/server
    /// surface; users select via `subjectTypes` and we resolve to one of these.
    public static let algorithms = ["auto", "vn-mask", "person", "saliency"]
    /// Canonical subject-type vocabulary for `--type` (CLI) and `type` (server).
    /// Single SSOT for parser validation, help text, and server docs.
    public static let subjectTypes = [
        "auto", "person", "product", "car", "animal", "graphic",
        "transportation", "saliency", "vn-mask",
    ]
    public static let channels = ["rgba", "alpha"]
    public static let bgFits = ["cover", "contain", "tile", "center"]
    public static let shadowTypes = ["auto", "drop", "3D", "car", "none"]

    public static let serverDefaultHost = "127.0.0.1"
    public static let serverDefaultPort = 8787
    public static let serverDefaultMaxBodyMB = 32

    public static let jsonSchemaVersion = 1

    public static func choices(_ values: [String]) -> String {
        values.joined(separator: "|")
    }
}
