import Foundation

/// The published filter catalogue. Empty at T2; one entry is appended for
/// every filter that actually ships with a real implementation in S3..S8.
/// NEVER add an entry here without the matching `Sources/Filters/<Name>.swift`
/// implementation, a registered dispatch in the pipeline, a passing unit-test
/// pixel assertion, and a per-filter doc.
public enum FilterCatalogue {
    public static let all: [FilterManifestEntry] = [
        // T5 #7 grayscale - SHIPPED
        .init(name: "grayscale", validLayers: [.fg, .bg, .all], signature: "grayscale", doc: "remove all colour saturation (backed by CIColorControls)"),
    ]
}
