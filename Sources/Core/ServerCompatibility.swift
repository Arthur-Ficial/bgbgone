import Foundation

public struct ServerAPIError: Error, Equatable, Sendable {
    public let status: Int
    public let code: String
    public let title: String
    public let detail: String?

    public init(status: Int, code: String, title: String, detail: String? = nil) {
        self.status = status
        self.code = code
        self.title = title
        self.detail = detail
    }

    public static func invalid(_ code: String, _ title: String, detail: String? = nil) -> ServerAPIError {
        ServerAPIError(status: 400, code: code, title: title, detail: detail)
    }

    public static func notImplementable(_ title: String) -> ServerAPIError {
        ServerAPIError(status: 501, code: "not_implementable", title: "NOT IMPLEMENTABLE: \(title)")
    }

    public func json() -> String {
        var object = """
        {"errors":[{"code":"\(JSONEscaper.escape(code))","title":"\(JSONEscaper.escape(title))"
        """
        if let detail {
            object += """
            ,"detail":"\(JSONEscaper.escape(detail))"
            """
        }
        object += "}]}"
        return object
    }
}

public enum ServerDimension: Sendable, Equatable {
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

public struct ServerRectSpec: Sendable, Equatable {
    public var x1: ServerDimension
    public var y1: ServerDimension
    public var x2: ServerDimension
    public var y2: ServerDimension

    public init(x1: ServerDimension, y1: ServerDimension, x2: ServerDimension, y2: ServerDimension) {
        self.x1 = x1
        self.y1 = y1
        self.x2 = x2
        self.y2 = y2
    }
}

public struct ServerEdgeInsets: Sendable, Equatable {
    public var top: ServerDimension
    public var right: ServerDimension
    public var bottom: ServerDimension
    public var left: ServerDimension

    public init(top: ServerDimension, right: ServerDimension, bottom: ServerDimension, left: ServerDimension) {
        self.top = top
        self.right = right
        self.bottom = bottom
        self.left = left
    }
}

public struct ServerPosition: Sendable, Equatable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public static let center = ServerPosition(x: 0.5, y: 0.5)
}

public enum ServerCompatibilityParser {
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
            throw ServerAPIError.invalid("invalid_size", "Invalid value for parameter 'size'")
        }
        return outputFormat == .png ? min(base, 10.0) : base
    }

    public static func parseQuality(_ raw: String?) throws -> Int {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return 92
        }
        guard let value = Int(raw.trimmingCharacters(in: .whitespacesAndNewlines)), (1...100).contains(value) else {
            throw ServerAPIError.invalid("invalid_quality", "Invalid quality parameter given")
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
            throw ServerAPIError.invalid(code, title)
        }
    }

    public static func parseROI(_ raw: String?) throws -> ServerRectSpec? {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        let parts = splitWords(raw)
        guard parts.count == 4 else {
            throw ServerAPIError.invalid("invalid_roi", "Invalid roi parameter given")
        }
        do {
            return ServerRectSpec(
                x1: try parseDimension(parts[0], defaultPercent: false),
                y1: try parseDimension(parts[1], defaultPercent: false),
                x2: try parseDimension(parts[2], defaultPercent: false),
                y2: try parseDimension(parts[3], defaultPercent: false)
            )
        } catch {
            throw ServerAPIError.invalid("invalid_roi", "Invalid roi parameter given")
        }
    }

    public static func parseCropMargins(_ raw: String?) throws -> ServerEdgeInsets? {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        let parts = splitWords(raw)
        guard [1, 2, 4].contains(parts.count) else {
            throw ServerAPIError.invalid("invalid_crop_margin", "Invalid crop_margin parameter given")
        }
        do {
            let dims = try parts.map { try parseDimension($0, defaultPercent: false) }
            switch dims.count {
            case 1:
                return ServerEdgeInsets(top: dims[0], right: dims[0], bottom: dims[0], left: dims[0])
            case 2:
                return ServerEdgeInsets(top: dims[0], right: dims[1], bottom: dims[0], left: dims[1])
            default:
                return ServerEdgeInsets(top: dims[0], right: dims[1], bottom: dims[2], left: dims[3])
            }
        } catch {
            throw ServerAPIError.invalid("invalid_crop_margin", "Invalid crop_margin parameter given")
        }
    }

    public static func parseScale(_ raw: String?) throws -> Double? {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        if normalize(raw) == "original" {
            return nil
        }
        guard raw.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("%"),
              let value = Double(raw.trimmingCharacters(in: .whitespacesAndNewlines).dropLast()) else {
            throw ServerAPIError.invalid("invalid_scale", "Invalid scale parameter given")
        }
        let normalized = value / 100.0
        guard (0.10...1.0).contains(normalized) else {
            throw ServerAPIError.invalid("invalid_scale", "Invalid scale parameter given")
        }
        return normalized
    }

    public static func parsePosition(_ raw: String?, scalePercent: Double?) throws -> ServerPosition? {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return scalePercent == nil ? nil : .center
        }
        let normalized = normalize(raw)
        if normalized == "original" {
            return nil
        }
        if normalized == "center" {
            return .center
        }
        let parts = splitWords(raw)
        guard [1, 2].contains(parts.count) else {
            throw ServerAPIError.invalid("invalid_position", "Invalid position parameter given")
        }
        do {
            let x = try parsePositionPercent(parts[0])
            let y = try parsePositionPercent(parts.count == 2 ? parts[1] : parts[0])
            return ServerPosition(x: x, y: y)
        } catch {
            throw ServerAPIError.invalid("invalid_position", "Invalid position parameter given")
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
            throw ServerAPIError.invalid("invalid_shadow_opacity", "Invalid shadow_opacity parameter given")
        }
        return n / 100.0
    }

    public static func parseFeather(_ raw: String?) throws -> Double? {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        guard let value = Double(raw.trimmingCharacters(in: .whitespacesAndNewlines)), value >= 0 else {
            throw ServerAPIError.invalid("invalid_feather", "Invalid feather parameter given")
        }
        return value
    }

    public static func parseThreshold(_ raw: String?) throws -> Double? {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        guard let value = Double(raw.trimmingCharacters(in: .whitespacesAndNewlines)), (0...1).contains(value) else {
            throw ServerAPIError.invalid("invalid_threshold", "Invalid threshold parameter given")
        }
        return value
    }

    public static func parseBgFit(_ raw: String?) throws -> BgFit? {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        guard let fit = BgFit(rawValue: normalize(raw)) else {
            throw ServerAPIError.invalid("invalid_bg_fit", "Invalid bg_fit parameter given")
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
            throw ServerAPIError.invalid("invalid_type", "Invalid type parameter given")
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

    private static func parseDimension(_ raw: String, defaultPercent: Bool) throws -> ServerDimension {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.hasSuffix("%") {
            guard let value = Double(trimmed.dropLast()), value >= 0 else {
                throw ServerAPIError.invalid("invalid_dimension", "Invalid dimension")
            }
            return .percent(value / 100.0)
        }
        if trimmed.hasSuffix("px") {
            guard let value = Double(trimmed.dropLast(2)), value >= 0 else {
                throw ServerAPIError.invalid("invalid_dimension", "Invalid dimension")
            }
            return .pixels(value)
        }
        guard let value = Double(trimmed), value >= 0 else {
            throw ServerAPIError.invalid("invalid_dimension", "Invalid dimension")
        }
        return defaultPercent ? .percent(value / 100.0) : .pixels(value)
    }

    private static func parsePositionPercent(_ raw: String) throws -> Double {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasSuffix("%"),
              let value = Double(trimmed.dropLast()) else {
            throw ServerAPIError.invalid("invalid_position", "Invalid position parameter given")
        }
        let normalized = value / 100.0
        guard (0...1).contains(normalized) else {
            throw ServerAPIError.invalid("invalid_position", "Invalid position parameter given")
        }
        return normalized
    }
}
