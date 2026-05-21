import Foundation

public enum BgBgOneError: Error, Equatable, Sendable {
    /// Bad flag, missing value, unknown option. Exit code 2.
    case parser(String)
    /// User-correctable issue (file not readable, refusing TTY, bad path). Exit code 1.
    case userError(String)
    /// No result (no subject detected, empty input). Exit code 2.
    case noResult(String)
    /// Apple framework gave up (Vision missing or returned an error). Exit code 3.
    case frameworkError(String)

    public var exitCode: Int32 {
        switch self {
        case .userError: return 1
        case .parser, .noResult: return 2
        case .frameworkError: return 3
        }
    }

    public var message: String {
        switch self {
        case .parser(let m), .userError(let m), .noResult(let m), .frameworkError(let m):
            return m
        }
    }
}
