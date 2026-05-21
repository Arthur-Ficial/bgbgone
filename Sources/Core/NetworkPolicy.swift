import Foundation

public enum NetworkPolicy {
    private static let blockedSchemes: Set<String> = ["http", "https", "ws", "wss"]

    public static func isBlockedNetworkScheme(_ scheme: String?) -> Bool {
        guard let scheme, !scheme.isEmpty else { return false }
        return blockedSchemes.contains(scheme.lowercased())
    }
}
