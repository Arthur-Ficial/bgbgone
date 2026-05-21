import Foundation

enum CapabilityProbe {
    static func isVNRemoveBackgroundAvailable() -> Bool {
        // VNGenerateForegroundInstanceMaskRequest provides the same capability surface as
        // any newer "remove background" request; we treat it as the canonical bg-remove API.
        if #available(macOS 14, *) { return true }
        return false
    }

    static func isVNForegroundInstanceMaskAvailable() -> Bool {
        if #available(macOS 14, *) { return true }
        return false
    }
}
