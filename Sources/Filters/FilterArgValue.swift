import Foundation
import BgBgOneCore

enum FilterArgValue {
    static func keyedNumber(_ args: [FilterArg], key: String, default def: Double, filter: String) throws -> Double {
        for arg in args {
            if case .keyed(let k, let value) = arg, k.lowercased() == key.lowercased() {
                return try number(value, arg: key, filter: filter)
            }
        }
        return def
    }

    static func keyedColor(_ args: [FilterArg], key: String = "color", default def: RGBA, filter: String) throws -> RGBA {
        for arg in args {
            if case .keyed(let k, let value) = arg, k.lowercased() == key.lowercased() {
                return try color(value, arg: key, filter: filter)
            }
        }
        return def
    }

    static func keyedPoint(_ args: [FilterArg], key: String, default def: (Double, Double), filter: String) throws -> (Double, Double) {
        for arg in args {
            if case .keyed(let k, let value) = arg, k.lowercased() == key.lowercased() {
                return try point(value, arg: key, filter: filter)
            }
        }
        return def
    }

    static func firstPoint(_ args: [FilterArg], default def: (Double, Double), filter: String) throws -> (Double, Double) {
        guard let first = args.first else { return def }
        switch first {
        case .value(let value), .keyed(_, let value):
            return try point(value, arg: "offset", filter: filter)
        }
    }

    static func positionalNumbers(_ args: [FilterArg], defaults: [Double], filter: String) throws -> [Double] {
        var out = defaults
        var index = 0
        for arg in args {
            guard case .value(let value) = arg else { continue }
            if index < out.count {
                out[index] = try number(value, arg: "value\(index + 1)", filter: filter)
            }
            index += 1
        }
        return out
    }

    static func choice(_ args: [FilterArg], default def: String, choices: Set<String>, filter: String) throws -> String {
        guard let first = args.first else { return def }
        let raw: String
        switch first {
        case .value(let value), .keyed(_, let value):
            raw = value.lowercased()
        }
        guard choices.contains(raw) else {
            throw fail(filter, "choice must be \(choices.sorted().joined(separator: "|")), got \(raw)", context: ["value": raw])
        }
        return raw
    }

    static func number(_ raw: String, arg: String, filter: String) throws -> Double {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(trimmed) else {
            throw fail(filter, "\(arg) is not a number", context: ["arg": arg, "value": raw])
        }
        return value
    }

    static func color(_ raw: String, arg: String, filter: String) throws -> RGBA {
        do {
            return try ColourParser.parse(ParameterParser.normalizedColor(raw))
        } catch {
            throw fail(filter, "\(arg) is not a valid colour", context: ["arg": arg, "value": raw])
        }
    }

    static func point(_ raw: String, arg: String, filter: String) throws -> (Double, Double) {
        let parts = raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard parts.count == 2,
              let x = Double(parts[0]),
              let y = Double(parts[1]) else {
            throw fail(filter, "\(arg) must be X,Y", context: ["arg": arg, "value": raw])
        }
        return (x, y)
    }

    private static func fail(_ filter: String, _ message: String, context: [String: String]) -> BgBgOneError {
        BgBgOneError.parser(
            ErrorCodes.parseFlagValueInvalid,
            "filter \(filter): \(message)",
            origin: "--filter",
            context: context.merging(["filter": filter]) { current, _ in current }
        )
    }
}
