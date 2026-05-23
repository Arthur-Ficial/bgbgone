import Foundation

/// One entry in the filter manifest. Used by `FilterRegistry.validate(chain)`
/// to reject unknown names and per-filter invalid layers BEFORE the pipeline
/// runs, and by `bgbgone --filters-list` to enumerate the catalogue.
///
/// The catalogue grows by exactly one entry per filter that actually ships
/// with a working implementation. Never declare a filter here that the
/// executable target does not implement - that would be a fake promise.
public struct FilterManifestEntry: Sendable, Equatable {
    public let name: String
    public let validLayers: Set<FilterLayer>
    public let aliases: Set<String>
    public let signature: String
    public let doc: String
    /// Whether applying the filter can introduce alpha into the composite
    /// (used by T57 JPEG alpha-loss refusal).
    public let producesAlpha: Bool

    public init(
        name: String,
        validLayers: Set<FilterLayer>,
        aliases: Set<String> = [],
        signature: String,
        doc: String,
        producesAlpha: Bool = false
    ) {
        self.name = name
        self.validLayers = validLayers
        self.aliases = aliases
        self.signature = signature
        self.doc = doc
        self.producesAlpha = producesAlpha
    }
}

public enum FilterRegistry {
    public static var all: [FilterManifestEntry] { FilterCatalogue.all }

    public static func find(_ name: String) -> FilterManifestEntry? {
        let lc = name.lowercased()
        if let direct = all.first(where: { $0.name == lc }) { return direct }
        return all.first(where: { $0.aliases.contains(lc) })
    }

    /// Validate a parsed chain against the manifest. Throws on unknown name
    /// or on a layer prefix the filter does not accept.
    public static func validate(_ chain: FilterChain) throws {
        for stage in chain.stages {
            for call in stage.calls {
                guard let entry = find(call.name) else {
                    throw BgBgOneError.parser(
                        ErrorCodes.parseFlagValueInvalid,
                        "unknown filter: \(call.name)",
                        origin: "--filter",
                        context: ["name": call.name],
                        hint: "run `bgbgone --filters-list` for the catalogue"
                    )
                }
                guard entry.validLayers.contains(stage.layer) else {
                    let valids = entry.validLayers.map { $0.rawValue }.sorted().joined(separator: "|")
                    throw BgBgOneError.parser(
                        ErrorCodes.parseFlagValueInvalid,
                        "filter \(entry.name) does not accept layer \(stage.layer.rawValue) (valid: \(valids))",
                        origin: "--filter",
                        context: ["name": entry.name, "layer": stage.layer.rawValue, "valid": valids]
                    )
                }
            }
        }
    }
}
