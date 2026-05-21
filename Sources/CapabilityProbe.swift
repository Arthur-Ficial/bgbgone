import Foundation

enum CapabilityProbe {
    static func isVNForegroundInstanceMaskAvailable() -> Bool {
        if #available(macOS 14, *) { return true }
        return false
    }

    static func isVNPersonSegmentationAvailable() -> Bool {
        if #available(macOS 12, *) { return true }
        return false
    }

    static func isVNSaliencyAvailable() -> Bool {
        if #available(macOS 10.15, *) { return true }
        return false
    }
}
