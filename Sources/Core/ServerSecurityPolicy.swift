public enum ServerSecurityPolicy {
    public static let defaultAllowedOrigins = [
        "http://127.0.0.1",
        "http://localhost",
        "http://[::1]",
    ]

    public static func isAllowedOrigin(_ origin: String?, allowedOrigins: [String]) -> Bool {
        guard let origin else { return true }
        if allowedOrigins.contains("*") { return true }

        for allowed in allowedOrigins {
            if matches(origin: origin, allowed: allowed) {
                return true
            }
            if allowed.hasPrefix("http://") {
                let httpsAllowed = "https://" + allowed.dropFirst("http://".count)
                if matches(origin: origin, allowed: String(httpsAllowed)) {
                    return true
                }
            }
        }

        return false
    }

    public static func isValidToken(provided: String?, expected: String?) -> Bool {
        guard let expected else { return true }
        guard let provided, !provided.isEmpty else { return false }
        let token = provided.hasPrefix("Bearer ") ? String(provided.dropFirst("Bearer ".count)) : provided
        return !token.isEmpty && token == expected
    }

    public static func isValidToken(authorization: String?, apiKey: String?, expected: String?) -> Bool {
        guard let expected else { return true }
        if let apiKey, !apiKey.isEmpty, apiKey == expected {
            return true
        }
        return isValidToken(provided: authorization, expected: expected)
    }

    public static func isLoopbackHost(_ host: String) -> Bool {
        switch host.lowercased() {
        case "127.0.0.1", "localhost", "::1", "[::1]":
            return true
        default:
            return false
        }
    }

    private static func matches(origin: String, allowed: String) -> Bool {
        origin == allowed || origin.hasPrefix(allowed + ":")
    }
}
