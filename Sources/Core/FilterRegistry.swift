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
    public let signature: String
    public let doc: String
    /// Whether applying the filter can introduce alpha into the composite
    /// (used by T57 JPEG alpha-loss refusal).
    public let producesAlpha: Bool

    public init(
        name: String,
        validLayers: Set<FilterLayer>,
        signature: String,
        doc: String,
        producesAlpha: Bool = false
    ) {
        self.name = name
        self.validLayers = validLayers
        self.signature = signature
        self.doc = doc
        self.producesAlpha = producesAlpha
    }
}

public struct FilterArgSchema: Sendable, Equatable {
    public enum Kind: Sendable, Equatable {
        case number
        case color
        case point
        case choice([String])
    }

    public let key: String?
    public let kind: Kind
    public let defaultValue: String?
    public let range: ClosedRange<Double>?

    public init(key: String? = nil, kind: Kind, defaultValue: String? = nil, range: ClosedRange<Double>? = nil) {
        self.key = key
        self.kind = kind
        self.defaultValue = defaultValue
        self.range = range
    }

    public var label: String { key ?? "value" }
}

public struct FilterSchema: Sendable, Equatable {
    public let positional: [FilterArgSchema]
    public let keyed: [FilterArgSchema]
    public let examples: [String]

    public init(positional: [FilterArgSchema] = [], keyed: [FilterArgSchema] = [], examples: [String] = []) {
        self.positional = positional
        self.keyed = keyed
        self.examples = examples
    }
}

public enum FilterRegistry {
    public static var all: [FilterManifestEntry] { FilterCatalogue.all }

    public static func find(_ name: String) -> FilterManifestEntry? {
        let lc = name.lowercased()
        return all.first(where: { $0.name == lc })
    }

    public static func schema(for name: String) -> FilterSchema {
        let n = find(name)?.name ?? name.lowercased()
        let unit = 0.0...1.0
        let colour = FilterArgSchema(key: "color", kind: .color)
        let amount = FilterArgSchema(key: "amount", kind: .number, defaultValue: "1", range: unit)
        switch n {
        case "grayscale", "negate", "comic", "emboss", "cutout", "matte":
            return FilterSchema(examples: [n])
        case "desaturate":
            return FilterSchema(positional: [.init(kind: .number, defaultValue: "1", range: unit)], keyed: [.init(key: "amount", kind: .number, defaultValue: "1", range: unit)], examples: ["desaturate=0.5"])
        case "sepia":
            return FilterSchema(positional: [.init(kind: .number, defaultValue: "1", range: unit)], keyed: [.init(key: "intensity", kind: .number, defaultValue: "1", range: unit)], examples: ["sepia=0.8", "sepia=intensity=0.8"])
        case "adjust":
            return FilterSchema(keyed: [
                .init(key: "brightness", kind: .number, defaultValue: "0", range: -1.0...1.0),
                .init(key: "contrast", kind: .number, defaultValue: "1", range: 0.0...4.0),
                .init(key: "saturation", kind: .number, defaultValue: "1", range: 0.0...4.0),
            ], examples: ["adjust=brightness=0.1:contrast=1.1:saturation=0.9"])
        case "gamma":
            return FilterSchema(positional: [.init(kind: .number, defaultValue: "1", range: 0.01...10.0)], keyed: [.init(key: "value", kind: .number, defaultValue: "1", range: 0.01...10.0)], examples: ["gamma=1.2"])
        case "exposure":
            return FilterSchema(positional: [.init(kind: .number, defaultValue: "0", range: -10.0...10.0)], keyed: [.init(key: "stops", kind: .number, defaultValue: "0", range: -10.0...10.0)], examples: ["exposure=1.0"])
        case "hue":
            return FilterSchema(positional: [.init(kind: .number, defaultValue: "0", range: -360.0...360.0)], keyed: [.init(key: "degrees", kind: .number, defaultValue: "0", range: -360.0...360.0)], examples: ["hue=120"])
        case "vibrance":
            return FilterSchema(positional: [.init(kind: .number, defaultValue: "0", range: -2.0...2.0)], keyed: [.init(key: "amount", kind: .number, defaultValue: "0", range: -2.0...2.0)], examples: ["vibrance=0.5"])
        case "blur", "box-blur":
            return FilterSchema(positional: [.init(kind: .number, defaultValue: "10", range: 0.0...500.0)], keyed: [.init(key: "radius", kind: .number, defaultValue: "10", range: 0.0...500.0)], examples: ["\(n)=15"])
        case "sharpen":
            return FilterSchema(positional: [.init(kind: .number, defaultValue: "0.4", range: 0.0...5.0)], keyed: [.init(key: "amount", kind: .number, defaultValue: "0.4", range: 0.0...5.0)], examples: ["sharpen=0.5"])
        case "posterize":
            return FilterSchema(positional: [.init(kind: .number, defaultValue: "6", range: 2.0...256.0)], keyed: [.init(key: "levels", kind: .number, defaultValue: "6", range: 2.0...256.0)], examples: ["posterize=4"])
        case "edges":
            return FilterSchema(positional: [.init(kind: .number, defaultValue: "1", range: 0.0...10.0)], keyed: [.init(key: "intensity", kind: .number, defaultValue: "1", range: 0.0...10.0)], examples: ["edges=2.5", "edges=intensity=2.5"])
        case "tint", "colorize":
            return FilterSchema(keyed: [colour, amount], examples: ["\(n)=color=#0066ff:amount=0.5"])
        case "temperature":
            return FilterSchema(positional: [.init(kind: .number, defaultValue: "6500", range: 1000.0...40000.0)], keyed: [.init(key: "kelvin", kind: .number, defaultValue: "6500", range: 1000.0...40000.0)], examples: ["temperature=9000"])
        case "levels":
            return FilterSchema(keyed: [
                .init(key: "black", kind: .number, defaultValue: "0", range: 0.0...255.0),
                .init(key: "white", kind: .number, defaultValue: "1", range: 0.0...255.0),
                .init(key: "gamma", kind: .number, defaultValue: "1", range: 0.01...10.0),
            ], examples: ["levels=black=20:white=235:gamma=1.0"])
        case "opacity":
            return FilterSchema(positional: [.init(kind: .number, defaultValue: "1", range: unit)], keyed: [.init(key: "value", kind: .number, defaultValue: "1", range: unit)], examples: ["opacity=0.7"])
        case "duotone":
            return FilterSchema(keyed: [
                .init(key: "dark", kind: .color, defaultValue: "#000"),
                .init(key: "light", kind: .color, defaultValue: "#fff"),
            ], examples: ["duotone=dark=#003366:light=#ffcc00"])
        case "motion-blur":
            return FilterSchema(positional: [
                .init(kind: .number, defaultValue: "20", range: 0.0...500.0),
                .init(kind: .number, defaultValue: "0", range: -360.0...360.0),
            ], keyed: [
                .init(key: "radius", kind: .number, defaultValue: "20", range: 0.0...500.0),
                .init(key: "angle", kind: .number, defaultValue: "0", range: -360.0...360.0),
            ], examples: ["motion-blur=radius=10:angle=45", "motion-blur=10:45"])
        case "zoom-blur":
            return FilterSchema(keyed: [
                .init(key: "center", kind: .point, defaultValue: "0.5,0.5", range: unit),
                .init(key: "amount", kind: .number, defaultValue: "20", range: 0.0...500.0),
            ], examples: ["zoom-blur=center=0.5,0.5:amount=20"])
        case "unsharp":
            return FilterSchema(positional: [
                .init(kind: .number, defaultValue: "2.5", range: 0.0...100.0),
                .init(kind: .number, defaultValue: "0.5", range: 0.0...10.0),
            ], keyed: [
                .init(key: "radius", kind: .number, defaultValue: "2.5", range: 0.0...100.0),
                .init(key: "intensity", kind: .number, defaultValue: "0.5", range: 0.0...10.0),
            ], examples: ["unsharp=radius=2.5:intensity=0.5", "unsharp=2.5:0.5"])
        case "pixelate":
            return FilterSchema(positional: [.init(kind: .number, defaultValue: "8", range: 1.0...500.0)], keyed: [.init(key: "size", kind: .number, defaultValue: "8", range: 1.0...500.0)], examples: ["pixelate=20"])
        case "edge-work":
            return FilterSchema(positional: [.init(kind: .number, defaultValue: "3", range: 0.0...100.0)], keyed: [.init(key: "radius", kind: .number, defaultValue: "3", range: 0.0...100.0)], examples: ["edge-work=3"])
        case "crystallize":
            return FilterSchema(positional: [.init(kind: .number, defaultValue: "20", range: 1.0...500.0)], keyed: [.init(key: "radius", kind: .number, defaultValue: "20", range: 1.0...500.0)], examples: ["crystallize=20"])
        case "pointillize":
            return FilterSchema(positional: [.init(kind: .number, defaultValue: "10", range: 1.0...500.0)], keyed: [.init(key: "radius", kind: .number, defaultValue: "10", range: 1.0...500.0)], examples: ["pointillize=5"])
        case "noise":
            return FilterSchema(positional: [.init(kind: .number, defaultValue: "0.2", range: unit)], keyed: [.init(key: "amount", kind: .number, defaultValue: "0.2", range: unit)], examples: ["noise=0.1"])
        case "vignette", "bloom", "gloom":
            return FilterSchema(positional: [
                .init(kind: .number, defaultValue: n == "vignette" ? "1" : "0.5", range: 0.0...10.0),
                .init(kind: .number, defaultValue: n == "vignette" ? "1" : "10", range: 0.0...500.0),
            ], keyed: [
                .init(key: "intensity", kind: .number, defaultValue: n == "vignette" ? "1" : "0.5", range: 0.0...10.0),
                .init(key: "radius", kind: .number, defaultValue: n == "vignette" ? "1" : "10", range: 0.0...500.0),
            ], examples: ["\(n)=intensity=0.5:radius=10", "\(n)=0.5:10"])
        case "vignette-effect":
            return FilterSchema(keyed: [
                .init(key: "center", kind: .point, defaultValue: "0.5,0.5", range: unit),
                .init(key: "radius", kind: .number, defaultValue: "1.5", range: 0.0...10.0),
                .init(key: "intensity", kind: .number, defaultValue: "1", range: 0.0...10.0),
            ], examples: ["vignette-effect=center=0.5,0.5:radius=1.5:intensity=1"])
        case "feather":
            return FilterSchema(positional: [.init(kind: .number, defaultValue: "4", range: 0.0...500.0)], keyed: [.init(key: "radius", kind: .number, defaultValue: "4", range: 0.0...500.0)], examples: ["feather=8"])
        case "threshold":
            return FilterSchema(positional: [.init(kind: .number, defaultValue: "0.5", range: unit)], keyed: [.init(key: "value", kind: .number, defaultValue: "0.5", range: unit)], examples: ["threshold=0.5"])
        case "expand", "contract":
            return FilterSchema(positional: [.init(kind: .number, defaultValue: "1", range: 0.0...500.0)], keyed: [.init(key: "pixels", kind: .number, defaultValue: "1", range: 0.0...500.0)], examples: ["\(n)=3"])
        case "outline":
            return FilterSchema(keyed: [colour, .init(key: "width", kind: .number, defaultValue: "3", range: 0.0...500.0)], examples: ["outline=color=#ffffff:width=3"])
        case "glow":
            return FilterSchema(keyed: [
                colour,
                .init(key: "radius", kind: .number, defaultValue: "10", range: 0.0...500.0),
                .init(key: "intensity", kind: .number, defaultValue: "0.5", range: 0.0...10.0),
            ], examples: ["glow=color=#ffe080:radius=10:intensity=0.6"])
        case "shadow", "inner-shadow":
            return FilterSchema(keyed: [
                .init(key: "blur", kind: .number, defaultValue: n == "shadow" ? "12" : "6", range: 0.0...500.0),
                .init(key: "offset", kind: .point, defaultValue: n == "shadow" ? "0,0" : "0,0"),
                .init(key: "opacity", kind: .number, defaultValue: "0.5", range: unit),
                colour,
            ], examples: ["\(n)=blur=12:offset=4,4:opacity=0.5:color=#000"])
        case "silhouette":
            return FilterSchema(keyed: [colour], examples: ["silhouette=color=#ff0000"])
        case "scale":
            return FilterSchema(positional: [.init(kind: .number, defaultValue: "1", range: 0.01...10.0)], keyed: [.init(key: "factor", kind: .number, defaultValue: "1", range: 0.01...10.0)], examples: ["scale=0.75"])
        case "translate":
            return FilterSchema(positional: [.init(kind: .point, defaultValue: "0,0")], keyed: [.init(key: "offset", kind: .point, defaultValue: "0,0")], examples: ["translate=-200,200"])
        case "rotate":
            return FilterSchema(positional: [.init(kind: .number, defaultValue: "0", range: -360.0...360.0)], keyed: [.init(key: "degrees", kind: .number, defaultValue: "0", range: -360.0...360.0)], examples: ["rotate=15"])
        case "flip":
            return FilterSchema(positional: [.init(kind: .choice(["horizontal", "vertical"]), defaultValue: "horizontal")], keyed: [.init(key: "axis", kind: .choice(["horizontal", "vertical"]), defaultValue: "horizontal")], examples: ["flip=horizontal"])
        default:
            return FilterSchema()
        }
    }

    /// Validate a parsed chain against the manifest. Throws on unknown name
    /// or on a layer prefix the filter does not accept.
    public static func validate(_ chain: FilterChain) throws {
        var sawComposite = false
        for stage in chain.stages {
            if stage.layer == .composite {
                sawComposite = true
            } else if sawComposite {
                throw BgBgOneError.parser(
                    ErrorCodes.parseFlagValueInvalid,
                    "layer \(stage.layer.rawValue) cannot run after composite: the foreground/background split is already flattened",
                    origin: "--filter",
                    context: ["layer": stage.layer.rawValue],
                    hint: "move fg:/bg:/all:/mask: stages before the composite: stage"
                )
            }
            for call in stage.calls {
                guard let entry = find(call.name) else {
                    let suggestion = nearestName(to: call.name)
                    throw BgBgOneError.parser(
                        ErrorCodes.parseFlagValueInvalid,
                        suggestion.map { "unknown filter: \(call.name); did you mean \($0)?" } ?? "unknown filter: \(call.name)",
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
                try validateArgs(call, schema: schema(for: entry.name), filterName: entry.name)
            }
        }
    }

    private static func validateArgs(_ call: FilterCall, schema: FilterSchema, filterName: String) throws {
        var positionalIndex = 0
        let keyedByName = Dictionary(uniqueKeysWithValues: schema.keyed.compactMap { spec in spec.key.map { ($0.lowercased(), spec) } })
        for arg in call.args {
            switch arg {
            case .value(let value):
                guard positionalIndex < schema.positional.count else {
                    throw argError(filterName, "too many positional arguments", context: ["value": value])
                }
                try validateValue(value, schema: schema.positional[positionalIndex], filterName: filterName)
                positionalIndex += 1
            case .keyed(let key, let value):
                guard let spec = keyedByName[key.lowercased()] else {
                    let allowed = keyedByName.keys.sorted().joined(separator: "|")
                    throw argError(filterName, "unknown argument \(key)", context: ["arg": key, "valid": allowed])
                }
                try validateValue(value, schema: spec, filterName: filterName)
            }
        }
        if schema.positional.isEmpty && schema.keyed.isEmpty && !call.args.isEmpty {
            throw argError(filterName, "does not take arguments")
        }
    }

    private static func validateValue(_ raw: String, schema: FilterArgSchema, filterName: String) throws {
        switch schema.kind {
        case .number:
            guard let value = Double(raw) else {
                throw argError(filterName, "\(schema.label) is not a number", context: ["arg": schema.label, "value": raw])
            }
            if let range = schema.range, !range.contains(value) {
                throw argError(
                    filterName,
                    "\(schema.label) must be \(format(range.lowerBound))..\(format(range.upperBound)), got \(raw)",
                    context: ["arg": schema.label, "value": raw]
                )
            }
        case .color:
            do {
                _ = try ColourParser.parse(ParameterParser.normalizedColor(raw))
            } catch {
                throw argError(filterName, "\(schema.label) is not a valid colour", context: ["arg": schema.label, "value": raw])
            }
        case .point:
            let parts = raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard parts.count == 2, let x = Double(parts[0]), let y = Double(parts[1]) else {
                throw argError(filterName, "\(schema.label) must be X,Y", context: ["arg": schema.label, "value": raw])
            }
            if let range = schema.range, (!range.contains(x) || !range.contains(y)) {
                throw argError(filterName, "\(schema.label) values must be \(format(range.lowerBound))..\(format(range.upperBound))", context: ["arg": schema.label, "value": raw])
            }
        case .choice(let choices):
            guard choices.contains(raw.lowercased()) else {
                throw argError(filterName, "\(schema.label) must be \(choices.joined(separator: "|"))", context: ["arg": schema.label, "value": raw])
            }
        }
    }

    private static func argError(_ filterName: String, _ message: String, context: [String: String] = [:]) -> BgBgOneError {
        BgBgOneError.parser(
            ErrorCodes.parseFlagValueInvalid,
            "filter \(filterName): \(message)",
            origin: "--filter",
            context: context.merging(["filter": filterName]) { current, _ in current }
        )
    }

    private static func nearestName(to raw: String) -> String? {
        let ranked = all
            .map(\.name)
            .map { ($0, levenshtein(raw.lowercased(), $0)) }
            .sorted { $0.1 < $1.1 }
        guard let best = ranked.first, best.1 <= 3 else { return nil }
        return best.0
    }

    private static func levenshtein(_ a: String, _ b: String) -> Int {
        let aa = Array(a), bb = Array(b)
        if aa.isEmpty { return bb.count }
        if bb.isEmpty { return aa.count }
        var previous = Array(0...bb.count)
        for (i, ca) in aa.enumerated() {
            var current = [i + 1] + Array(repeating: 0, count: bb.count)
            for (j, cb) in bb.enumerated() {
                current[j + 1] = min(
                    previous[j + 1] + 1,
                    current[j] + 1,
                    previous[j] + (ca == cb ? 0 : 1)
                )
            }
            previous = current
        }
        return previous[bb.count]
    }

    private static func format(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(value)
    }
}
