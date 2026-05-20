import Foundation
import BgBgOneCore

// Mirror of DenyNetworkURLProtocol's scheme test, kept here so we can run it without
// pulling URLProtocol's full URL Loading System into the test target. The contract is:
// http/https/ws/wss are blocked; everything else passes through.

func isNetworkScheme(_ scheme: String?) -> Bool {
    guard let s = scheme?.lowercased() else { return false }
    return s == "http" || s == "https" || s == "ws" || s == "wss"
}

func runNetworkGuardTests() {
    test("http is a network scheme") { try assertTrue(isNetworkScheme("http")) }
    test("HTTPS (case-insensitive)") { try assertTrue(isNetworkScheme("HTTPS")) }
    test("ws / wss are network schemes") {
        try assertTrue(isNetworkScheme("ws"))
        try assertTrue(isNetworkScheme("wss"))
    }
    test("file is not a network scheme") { try assertFalse(isNetworkScheme("file")) }
    test("data is not a network scheme") { try assertFalse(isNetworkScheme("data")) }
    test("nil scheme is not a network scheme") { try assertFalse(isNetworkScheme(nil)) }
    test("empty scheme is not a network scheme") { try assertFalse(isNetworkScheme("")) }
}
