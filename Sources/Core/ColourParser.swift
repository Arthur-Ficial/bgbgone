import Foundation

public enum ColourParser {

    private static let namedColours: [String: RGBA] = [
        "white": RGBA(r: 1, g: 1, b: 1),
        "black": RGBA(r: 0, g: 0, b: 0),
        "red":   RGBA(r: 1, g: 0, b: 0),
        "green": RGBA(r: 0, g: 1, b: 0),
        "blue":  RGBA(r: 0, g: 0, b: 1),
        "yellow": RGBA(r: 1, g: 1, b: 0),
        "cyan":   RGBA(r: 0, g: 1, b: 1),
        "magenta": RGBA(r: 1, g: 0, b: 1),
        "grey":  RGBA(r: 0.5, g: 0.5, b: 0.5),
        "gray":  RGBA(r: 0.5, g: 0.5, b: 0.5),
        "transparent": RGBA(r: 0, g: 0, b: 0, a: 0),
    ]

    public static func parse(_ raw: String) throws -> RGBA {
        let s = raw.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") {
            return try parseHex(String(s.dropFirst()))
        }
        if s.hasPrefix("rgb:") {
            return try parseRGB(String(s.dropFirst("rgb:".count)), hasAlpha: false)
        }
        if s.hasPrefix("rgba:") {
            return try parseRGB(String(s.dropFirst("rgba:".count)), hasAlpha: true)
        }
        if let c = namedColours[s.lowercased()] {
            return c
        }
        throw BgBgOneError.parser("unknown colour: \(raw)")
    }

    private static func parseHex(_ hex: String) throws -> RGBA {
        let chars = Array(hex)
        guard chars.allSatisfy({ $0.isHexDigit }) else {
            throw BgBgOneError.parser("invalid hex digits in #\(hex)")
        }
        let (r, g, b, a): (Int, Int, Int, Int)
        switch chars.count {
        case 3:
            r = Int(String(chars[0]) + String(chars[0]), radix: 16)!
            g = Int(String(chars[1]) + String(chars[1]), radix: 16)!
            b = Int(String(chars[2]) + String(chars[2]), radix: 16)!
            a = 255
        case 4:
            r = Int(String(chars[0]) + String(chars[0]), radix: 16)!
            g = Int(String(chars[1]) + String(chars[1]), radix: 16)!
            b = Int(String(chars[2]) + String(chars[2]), radix: 16)!
            a = Int(String(chars[3]) + String(chars[3]), radix: 16)!
        case 6:
            r = Int(hex.prefix(2), radix: 16)!
            g = Int(hex.dropFirst(2).prefix(2), radix: 16)!
            b = Int(hex.dropFirst(4).prefix(2), radix: 16)!
            a = 255
        case 8:
            r = Int(hex.prefix(2), radix: 16)!
            g = Int(hex.dropFirst(2).prefix(2), radix: 16)!
            b = Int(hex.dropFirst(4).prefix(2), radix: 16)!
            a = Int(hex.dropFirst(6).prefix(2), radix: 16)!
        default:
            throw BgBgOneError.parser("hex colour must be 3, 4, 6, or 8 digits: #\(hex)")
        }
        return RGBA(r: Double(r) / 255.0, g: Double(g) / 255.0, b: Double(b) / 255.0, a: Double(a) / 255.0)
    }

    private static func parseRGB(_ body: String, hasAlpha: Bool) throws -> RGBA {
        let parts = body.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let expected = hasAlpha ? 4 : 3
        guard parts.count == expected else {
            throw BgBgOneError.parser("\(hasAlpha ? "rgba" : "rgb"): expected \(expected) components, got \(parts.count)")
        }
        let ints = try parts.map { (p: String) -> Int in
            guard let v = Int(p), (0...255).contains(v) else {
                throw BgBgOneError.parser("component out of range 0..255: \(p)")
            }
            return v
        }
        let a = hasAlpha ? Double(ints[3]) / 255.0 : 1.0
        return RGBA(
            r: Double(ints[0]) / 255.0,
            g: Double(ints[1]) / 255.0,
            b: Double(ints[2]) / 255.0,
            a: a
        )
    }
}
