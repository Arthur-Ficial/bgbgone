import Foundation

public struct ParameterParseError: Error, Equatable, Sendable {
    public let code: String
    public let message: String
    public let detail: String?

    public init(code: String, message: String, detail: String? = nil) {
        self.code = code
        self.message = message
        self.detail = detail
    }

    public static func invalid(_ code: String, _ message: String, detail: String? = nil) -> ParameterParseError {
        ParameterParseError(code: code, message: message, detail: detail)
    }

    public func bgError(origin: String? = nil) -> BgBgOneError {
        var context: [String: String] = ["field_code": code]
        if let detail, !detail.isEmpty {
            context["detail"] = detail
        }
        return BgBgOneError.parser(code, message, origin: origin, context: context)
    }
}

public enum DimensionSpec: Sendable, Equatable {
    case pixels(Double)
    case percent(Double)

    public func resolve(total: Double) -> Double {
        switch self {
        case .pixels(let value):
            return value
        case .percent(let value):
            return total * value
        }
    }
}

public struct RectSpec: Sendable, Equatable {
    public var x1: DimensionSpec
    public var y1: DimensionSpec
    public var x2: DimensionSpec
    public var y2: DimensionSpec

    public init(x1: DimensionSpec, y1: DimensionSpec, x2: DimensionSpec, y2: DimensionSpec) {
        self.x1 = x1
        self.y1 = y1
        self.x2 = x2
        self.y2 = y2
    }
}

public struct EdgeInsetsSpec: Sendable, Equatable {
    public var top: DimensionSpec
    public var right: DimensionSpec
    public var bottom: DimensionSpec
    public var left: DimensionSpec

    public init(top: DimensionSpec, right: DimensionSpec, bottom: DimensionSpec, left: DimensionSpec) {
        self.top = top
        self.right = right
        self.bottom = bottom
        self.left = left
    }
}

public enum ParameterParser {
    public static func parseSize(_ raw: String?, outputFormat: OutputFormat) throws -> Double? {
        let normalized = normalize(raw ?? "preview")
        let base: Double
        switch normalized {
        case "preview":
            base = 0.25
        case "full", "auto":
            base = 25.0
        case "50mp":
            base = 50.0
        default:
            throw ParameterParseError.invalid("invalid_size", "Invalid value for parameter 'size'")
        }
        return outputFormat == .png ? min(base, 10.0) : base
    }

    public static func parseQuality(_ raw: String?) throws -> Int {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return 92
        }
        guard let value = Int(raw.trimmingCharacters(in: .whitespacesAndNewlines)), (1...100).contains(value) else {
            throw ParameterParseError.invalid("invalid_quality", "Invalid quality parameter given")
        }
        return value
    }

    public static func parseBoolean(_ raw: String?, default defaultValue: Bool, code: String, title: String) throws -> Bool {
        guard let raw, !raw.isEmpty else { return defaultValue }
        switch normalize(raw) {
        case "1", "true", "yes", "y", "on":
            return true
        case "0", "false", "no", "n", "off":
            return false
        default:
            throw ParameterParseError.invalid(code, title)
        }
    }

    public static func parseROI(_ raw: String?) throws -> RectSpec? {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        let parts = splitWords(raw)
        guard parts.count == 4 else {
            throw ParameterParseError.invalid("invalid_roi", "Invalid roi parameter given")
        }
        do {
            return RectSpec(
                x1: try parseDimension(parts[0], defaultPercent: false),
                y1: try parseDimension(parts[1], defaultPercent: false),
                x2: try parseDimension(parts[2], defaultPercent: false),
                y2: try parseDimension(parts[3], defaultPercent: false)
            )
        } catch {
            throw ParameterParseError.invalid("invalid_roi", "Invalid roi parameter given")
        }
    }

    public static func parseCropMargins(_ raw: String?) throws -> EdgeInsetsSpec? {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        let parts = splitWords(raw)
        guard [1, 2, 4].contains(parts.count) else {
            throw ParameterParseError.invalid("invalid_crop_margin", "Invalid crop-margin parameter given")
        }
        do {
            let dims = try parts.map { try parseDimension($0, defaultPercent: false) }
            switch dims.count {
            case 1:
                return EdgeInsetsSpec(top: dims[0], right: dims[0], bottom: dims[0], left: dims[0])
            case 2:
                return EdgeInsetsSpec(top: dims[0], right: dims[1], bottom: dims[0], left: dims[1])
            default:
                return EdgeInsetsSpec(top: dims[0], right: dims[1], bottom: dims[2], left: dims[3])
            }
        } catch {
            throw ParameterParseError.invalid("invalid_crop_margin", "Invalid crop-margin parameter given")
        }
    }

    public static func parseShadowOpacity(_ raw: String?) throws -> Double {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return 0.50
        }
        if normalize(raw) == "auto" {
            return 0.50
        }
        guard let n = Double(raw.trimmingCharacters(in: .whitespacesAndNewlines)), (0...100).contains(n) else {
            throw ParameterParseError.invalid("invalid_shadow_opacity", "Invalid shadow-opacity parameter given")
        }
        return n / 100.0
    }

    public static func parseBgFit(_ raw: String?) throws -> BgFit? {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        guard let fit = BgFit(rawValue: normalize(raw)) else {
            throw ParameterParseError.invalid("invalid_bg_fit", "Invalid bg-fit parameter given")
        }
        return fit
    }

    public static func parseForegroundType(_ raw: String?) throws -> (algo: Algo, typeValue: String) {
        let type = normalize(raw ?? "auto")
        switch type {
        case "", "auto":
            return (.auto, "other")
        case "person":
            return (.person, "person")
        case "product", "car", "animal", "graphic", "transportation":
            return (.auto, type)
        case "saliency":
            return (.saliency, "other")
        case "vn-mask":
            return (.vnMask, "other")
        default:
            throw ParameterParseError.invalid("invalid_type", "Invalid type parameter given")
        }
    }

    public static func normalizedColor(_ value: String) -> String {
        let raw = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.hasPrefix("#") || raw.hasPrefix("rgb:") || raw.hasPrefix("rgba:") {
            return raw
        }
        if raw.allSatisfy(\.isHexDigit), [3, 4, 6, 8].contains(raw.count) {
            return "#\(raw)"
        }
        return raw
    }

    public static func normalize(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func splitWords(_ raw: String) -> [String] {
        raw.split { $0 == " " || $0 == "\t" || $0 == "\n" || $0 == "\r" }.map(String.init)
    }

    private static func parseDimension(_ raw: String, defaultPercent: Bool) throws -> DimensionSpec {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.hasSuffix("%") {
            guard let value = Double(trimmed.dropLast()), value >= 0 else {
                throw ParameterParseError.invalid("invalid_dimension", "Invalid dimension")
            }
            return .percent(value / 100.0)
        }
        if trimmed.hasSuffix("px") {
            guard let value = Double(trimmed.dropLast(2)), value >= 0 else {
                throw ParameterParseError.invalid("invalid_dimension", "Invalid dimension")
            }
            return .pixels(value)
        }
        guard let value = Double(trimmed), value >= 0 else {
            throw ParameterParseError.invalid("invalid_dimension", "Invalid dimension")
        }
        return defaultPercent ? .percent(value / 100.0) : .pixels(value)
    }

}
