import Foundation

/// Structured error with stable machine-readable `code`, human `message`, optional
/// `origin` (where the error came from - flag, file path), key/value `context`,
/// and optional `hint` (suggested fix). Renders as multi-line stderr by default,
/// JSON envelope under `--json`, and the same JSON envelope from the HTTP surface.
///
/// Categories map 1:1 to UNIX exit codes:
///   .user      -> 1
///   .parser    -> 2
///   .noResult  -> 2
///   .framework -> 3
public struct BgBgOneError: Error, Equatable, Sendable {
    public let code: String
    public let category: Category
    public let message: String
    public let origin: String?
    public let context: [String: String]
    public let hint: String?

    public enum Category: String, Sendable, Equatable {
        case parser
        case user
        case noResult = "no_result"
        case framework
    }

    public init(
        code: String,
        category: Category,
        message: String,
        origin: String? = nil,
        context: [String: String] = [:],
        hint: String? = nil
    ) {
        self.code = code
        self.category = category
        self.message = message
        self.origin = origin
        self.context = context
        self.hint = hint
    }

    public var exitCode: Int32 {
        switch category {
        case .user: return 1
        case .parser, .noResult: return 2
        case .framework: return 3
        }
    }

    // MARK: - Factory helpers (preserve call-site readability)

    public static func parser(
        _ code: String,
        _ message: String,
        origin: String? = nil,
        context: [String: String] = [:],
        hint: String? = nil
    ) -> BgBgOneError {
        BgBgOneError(
            code: code, category: .parser,
            message: message, origin: origin, context: context, hint: hint
        )
    }

    public static func userError(
        _ code: String,
        _ message: String,
        origin: String? = nil,
        context: [String: String] = [:],
        hint: String? = nil
    ) -> BgBgOneError {
        BgBgOneError(
            code: code, category: .user,
            message: message, origin: origin, context: context, hint: hint
        )
    }

    public static func noResult(
        _ code: String,
        _ message: String,
        origin: String? = nil,
        context: [String: String] = [:],
        hint: String? = nil
    ) -> BgBgOneError {
        BgBgOneError(
            code: code, category: .noResult,
            message: message, origin: origin, context: context, hint: hint
        )
    }

    public static func frameworkError(
        _ code: String,
        _ message: String,
        origin: String? = nil,
        context: [String: String] = [:],
        hint: String? = nil
    ) -> BgBgOneError {
        BgBgOneError(
            code: code, category: .framework,
            message: message, origin: origin, context: context, hint: hint
        )
    }
}
