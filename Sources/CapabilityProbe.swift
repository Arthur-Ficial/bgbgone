import Foundation

enum CapabilityProbe {
    static func isImagePlaygroundAvailable() -> Bool {
        if #available(macOS 15.2, *) {
            // ImageCreator is part of the ImagePlayground framework. Availability is gated by
            // both OS version and the user enabling Apple Intelligence.
            return Bundle(identifier: "com.apple.ImagePlayground") != nil
        }
        return false
    }

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
