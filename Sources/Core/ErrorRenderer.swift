import Foundation

/// Single source of truth for rendering `BgBgOneError` to stderr or JSON.
/// No other code formats errors. Same JSON shape used by CLI `--json` and HTTP.
public enum ErrorRenderer {

    /// Multi-line human format for stderr (default).
    /// Honours `--quiet` (single line, message only) and `NO_COLOR` (no ANSI).
    public static func stderrText(_ e: BgBgOneError, quiet: Bool = false) -> String {
        if quiet {
            return "bgbgone: \(e.message)\n"
        }
        var out = "bgbgone: error\n"
        out += "  code:    \(e.code)\n"
        out += "  message: \(e.message)\n"
        if let origin = e.origin, !origin.isEmpty {
            out += "  where:   \(origin)\n"
        }
        if !e.context.isEmpty {
            let pairs = e.context
                .sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: " ")
            out += "  context: \(pairs)\n"
        }
        if let hint = e.hint, !hint.isEmpty {
            out += "  hint:    \(hint)\n"
        }
        return out
    }

    /// Stable JSON envelope: `{"ok":false,"error":{...}}`. Used by `--json`
    /// CLI output and by the HTTP `/bgbgone` surface on error.
    public static func jsonEnvelope(_ e: BgBgOneError) -> String {
        var fields: [(String, String)] = []
        fields.append(("code", quote(e.code)))
        fields.append(("category", quote(e.category.rawValue)))
        fields.append(("exit", String(e.exitCode)))
        fields.append(("message", quote(e.message)))
        if let origin = e.origin, !origin.isEmpty {
            fields.append(("where", quote(origin)))
        }
        if !e.context.isEmpty {
            let parts = e.context
                .sorted { $0.key < $1.key }
                .map { "\(quote($0.key)):\(quote($0.value))" }
                .joined(separator: ",")
            fields.append(("context", "{\(parts)}"))
        }
        if let hint = e.hint, !hint.isEmpty {
            fields.append(("hint", quote(hint)))
        }
        let inner = fields.map { "\(quote($0.0)):\($0.1)" }.joined(separator: ",")
        return "{\"ok\":false,\"schema\":\"bgbgone.run.v\(CLIContract.jsonSchemaVersion)\",\"error\":{\(inner)}}"
    }

    /// HTTP status code derived from category. Parser/user -> 400,
    /// no-result -> 422, framework -> 500. UNIX exit codes (0/1/2/3)
    /// remain unchanged - this is HTTP-only.
    public static func httpStatus(_ e: BgBgOneError) -> Int {
        switch e.category {
        case .parser, .user: return 400
        case .noResult: return 422
        case .framework: return 500
        }
    }

    private static func quote(_ s: String) -> String {
        "\"\(JSONEscaper.escape(s))\""
    }
}
