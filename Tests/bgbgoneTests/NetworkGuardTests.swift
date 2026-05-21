import BgBgOneCore

func runNetworkGuardTests() {
    test("http is a network scheme") { try assertTrue(NetworkPolicy.isBlockedNetworkScheme("http")) }
    test("HTTPS (case-insensitive)") { try assertTrue(NetworkPolicy.isBlockedNetworkScheme("HTTPS")) }
    test("ws / wss are network schemes") {
        try assertTrue(NetworkPolicy.isBlockedNetworkScheme("ws"))
        try assertTrue(NetworkPolicy.isBlockedNetworkScheme("wss"))
    }
    test("file is not a network scheme") { try assertFalse(NetworkPolicy.isBlockedNetworkScheme("file")) }
    test("data is not a network scheme") { try assertFalse(NetworkPolicy.isBlockedNetworkScheme("data")) }
    test("nil scheme is not a network scheme") { try assertFalse(NetworkPolicy.isBlockedNetworkScheme(nil)) }
    test("empty scheme is not a network scheme") { try assertFalse(NetworkPolicy.isBlockedNetworkScheme("")) }
}
