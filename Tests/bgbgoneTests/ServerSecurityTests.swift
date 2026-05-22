import BgBgOneCore

func runServerSecurityTests() {
    let defaults = ServerSecurityPolicy.defaultAllowedOrigins

    test("nil Origin is allowed for non-browser clients") {
        try assertTrue(ServerSecurityPolicy.isAllowedOrigin(nil, allowedOrigins: defaults))
    }

    test("localhost origins and port variants are allowed") {
        try assertTrue(ServerSecurityPolicy.isAllowedOrigin("http://localhost", allowedOrigins: defaults))
        try assertTrue(ServerSecurityPolicy.isAllowedOrigin("http://localhost:3000", allowedOrigins: defaults))
        try assertTrue(ServerSecurityPolicy.isAllowedOrigin("http://127.0.0.1:5173", allowedOrigins: defaults))
        try assertTrue(ServerSecurityPolicy.isAllowedOrigin("https://localhost:8443", allowedOrigins: defaults))
    }

    test("foreign and localhost-prefix origins are rejected") {
        try assertFalse(ServerSecurityPolicy.isAllowedOrigin("http://example.com", allowedOrigins: defaults))
        try assertFalse(ServerSecurityPolicy.isAllowedOrigin("http://localhost.example.com", allowedOrigins: defaults))
        try assertFalse(ServerSecurityPolicy.isAllowedOrigin("http://127.0.0.2", allowedOrigins: defaults))
        try assertFalse(ServerSecurityPolicy.isAllowedOrigin("", allowedOrigins: defaults))
    }

    test("wildcard origin list allows all origins") {
        try assertTrue(ServerSecurityPolicy.isAllowedOrigin("http://example.com", allowedOrigins: ["*"]))
    }

    test("Bearer token validation accepts bearer and bare forms") {
        try assertTrue(ServerSecurityPolicy.isValidToken(provided: "Bearer secret", expected: "secret"))
        try assertTrue(ServerSecurityPolicy.isValidToken(provided: "secret", expected: "secret"))
        try assertFalse(ServerSecurityPolicy.isValidToken(provided: "Bearer wrong", expected: "secret"))
        try assertFalse(ServerSecurityPolicy.isValidToken(provided: nil, expected: "secret"))
        try assertTrue(ServerSecurityPolicy.isValidToken(provided: nil, expected: nil))
    }

    test("health auth is only skipped for loopback unless public health is set") {
        var loopback = ServerConfig()
        loopback.token = "secret"
        loopback.host = "127.0.0.1"
        try assertFalse(loopback.healthRequiresAuthentication)

        var exposed = ServerConfig()
        exposed.token = "secret"
        exposed.host = "0.0.0.0"
        try assertTrue(exposed.healthRequiresAuthentication)

        exposed.publicHealth = true
        try assertFalse(exposed.healthRequiresAuthentication)
    }

    test("authorization header without Bearer prefix still validates") {
        try assertTrue(ServerSecurityPolicy.isValidToken(authorization: "secret", apiKey: nil, expected: "secret"))
        try assertFalse(ServerSecurityPolicy.isValidToken(authorization: "Bearer ", apiKey: nil, expected: "secret"))
    }

    test("X-API-Key takes precedence over a missing Authorization header") {
        try assertTrue(ServerSecurityPolicy.isValidToken(authorization: nil, apiKey: "secret", expected: "secret"))
        try assertFalse(ServerSecurityPolicy.isValidToken(authorization: nil, apiKey: "wrong", expected: "secret"))
    }

    test("isLoopbackHost recognises loopback variants and IPv6 bracket form") {
        try assertTrue(ServerSecurityPolicy.isLoopbackHost("127.0.0.1"))
        try assertTrue(ServerSecurityPolicy.isLoopbackHost("localhost"))
        try assertTrue(ServerSecurityPolicy.isLoopbackHost("::1"))
        try assertTrue(ServerSecurityPolicy.isLoopbackHost("[::1]"))
        try assertFalse(ServerSecurityPolicy.isLoopbackHost("0.0.0.0"))
        try assertFalse(ServerSecurityPolicy.isLoopbackHost("10.0.0.1"))
    }

    test("HTTPS variant of an http://-allowed origin is also accepted") {
        let allowed = ["http://app.example.test"]
        try assertTrue(ServerSecurityPolicy.isAllowedOrigin("http://app.example.test", allowedOrigins: allowed))
        try assertTrue(ServerSecurityPolicy.isAllowedOrigin("https://app.example.test", allowedOrigins: allowed))
        try assertTrue(ServerSecurityPolicy.isAllowedOrigin("https://app.example.test:8443", allowedOrigins: allowed))
    }

    test("IPv6 loopback ([::1]) is an allowed origin under defaults") {
        try assertTrue(ServerSecurityPolicy.isAllowedOrigin("http://[::1]", allowedOrigins: ServerSecurityPolicy.defaultAllowedOrigins))
        try assertTrue(ServerSecurityPolicy.isAllowedOrigin("http://[::1]:8787", allowedOrigins: ServerSecurityPolicy.defaultAllowedOrigins))
    }
}
