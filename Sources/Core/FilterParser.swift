import Foundation

/// Parses one `--filter` chain string into a typed `FilterChain` AST.
/// Grammar (locked in epic #1):
///
///   chain  := stage (";" stage)*
///   stage  := [layer ":"] filter ("," filter)*
///   layer  := "fg" | "bg" | "all" | "mask"
///   filter := name ("=" arg (":" arg)*)?
///   arg    := value | key "=" value
///
/// Whitespace around delimiters is tolerated. Empty string -> empty chain.
public enum FilterParser {

    public static func parse(_ raw: String) throws -> FilterChain {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return FilterChain(stages: []) }

        let stageTokens = splitTopLevel(trimmed, by: ";")
        var stages: [FilterStage] = []
        for (i, st) in stageTokens.enumerated() {
            let s = st.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !s.isEmpty else {
                throw err("empty stage at position \(i + 1) in --filter \"\(raw)\"",
                          context: ["chain": raw, "position": String(i + 1)])
            }
            stages.append(try parseStage(s, originalChain: raw))
        }
        return FilterChain(stages: stages)
    }

    // MARK: - stage

    private static func parseStage(_ s: String, originalChain: String) throws -> FilterStage {
        var layer: FilterLayer = .all
        var body = s
        if let colonIdx = s.firstIndex(of: ":") {
            let prefix = String(s[..<colonIdx]).trimmingCharacters(in: .whitespaces)
            if let known = FilterLayer(rawValue: prefix) {
                layer = known
                body = String(s[s.index(after: colonIdx)...]).trimmingCharacters(in: .whitespaces)
            }
        }

        let filterTokens = splitStageByFilterComma(body)
        var calls: [FilterCall] = []
        for tok in filterTokens {
            let t = tok.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !t.isEmpty else {
                throw err("empty filter inside stage \"\(s)\" of --filter \"\(originalChain)\"",
                          context: ["chain": originalChain, "stage": s])
            }
            calls.append(try parseCall(t, stage: s, originalChain: originalChain))
        }
        guard !calls.isEmpty else {
            throw err("stage \"\(s)\" has no filters in --filter \"\(originalChain)\"",
                      context: ["chain": originalChain, "stage": s])
        }
        return FilterStage(layer: layer, calls: calls)
    }

    // MARK: - call

    private static func parseCall(_ s: String, stage: String, originalChain: String) throws -> FilterCall {
        guard let eqIdx = s.firstIndex(of: "=") else {
            // bare name
            try validateName(s, stage: stage, originalChain: originalChain)
            return FilterCall(name: s, args: [])
        }
        let name = String(s[..<eqIdx]).trimmingCharacters(in: .whitespaces)
        try validateName(name, stage: stage, originalChain: originalChain)
        let argsBody = String(s[s.index(after: eqIdx)...])

        let argTokens = splitTopLevel(argsBody, by: ":")
        var args: [FilterArg] = []
        for tok in argTokens {
            let t = tok.trimmingCharacters(in: .whitespaces)
            guard !t.isEmpty else {
                throw err("empty arg in \"\(name)\" of --filter \"\(originalChain)\"",
                          context: ["chain": originalChain, "name": name])
            }
            if let kEq = t.firstIndex(of: "=") {
                let k = String(t[..<kEq]).trimmingCharacters(in: .whitespaces)
                let v = String(t[t.index(after: kEq)...]).trimmingCharacters(in: .whitespaces)
                guard !k.isEmpty, !v.isEmpty else {
                    throw err("malformed key=value arg \"\(t)\" in \"\(name)\" of --filter \"\(originalChain)\"",
                              context: ["chain": originalChain, "name": name, "arg": t])
                }
                args.append(.keyed(key: k, value: v))
            } else {
                args.append(.value(t))
            }
        }
        return FilterCall(name: name, args: args)
    }

    private static func validateName(_ name: String, stage: String, originalChain: String) throws {
        guard !name.isEmpty else {
            throw err("missing filter name in stage \"\(stage)\" of --filter \"\(originalChain)\"",
                      context: ["chain": originalChain, "stage": stage])
        }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")
        if let scalar = name.unicodeScalars.first(where: { !allowed.contains($0) }) {
            throw err("invalid filter name \"\(name)\" (illegal char '\(scalar)') in --filter \"\(originalChain)\"",
                      context: ["chain": originalChain, "name": name])
        }
    }

    // MARK: - split helpers

    /// Split a string on `delimiter` but only at the top level (no nesting needed yet,
    /// but trims and ignores leading/trailing empty segments cleanly).
    private static func splitTopLevel(_ s: String, by delimiter: Character) -> [String] {
        s.split(separator: delimiter, omittingEmptySubsequences: false).map(String.init)
    }

    /// Split the body of a stage into filter tokens. The `,` character serves
    /// double-duty in the grammar: between filters (`grayscale,blur=10`) AND
    /// inside value pairs (`offset=4,4`). Disambiguate: a `,` is a filter
    /// separator only when the next non-space character starts a valid filter
    /// name (a letter or `_`). Otherwise it stays inside the current value.
    private static func splitStageByFilterComma(_ s: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        let chars = Array(s)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if c == "," {
                var j = i + 1
                while j < chars.count, chars[j].isWhitespace { j += 1 }
                let next = j < chars.count ? chars[j] : nil
                if let n = next, n.isLetter || n == "_" {
                    tokens.append(current)
                    current = ""
                    i = j
                    continue
                }
            }
            current.append(c)
            i += 1
        }
        tokens.append(current)
        return tokens
    }

    private static func err(_ message: String, context: [String: String]) -> BgBgOneError {
        BgBgOneError.parser(
            ErrorCodes.parseFlagValueInvalid,
            message,
            origin: "--filter",
            context: context,
            hint: "grammar: chain := stage (\";\" stage)* ; stage := [layer:]filter (\",\" filter)* ; layer in fg|bg|all|mask"
        )
    }
}
