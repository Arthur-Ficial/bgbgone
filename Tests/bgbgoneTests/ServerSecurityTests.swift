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
}
