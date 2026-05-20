import Foundation
import CoreGraphics
import BgBgOneCore

#if canImport(ImagePlayground)
import ImagePlayground
#endif

enum GenerativeBg {
    /// Generate an image from a prompt via Apple Intelligence's Image Playground.
    /// Bridges async ImageCreator into the sync pipeline via a Task + DispatchSemaphore.
    static func generate(prompt: String, style: GenStyle, size: CGSize) throws -> CGImage {
        #if canImport(ImagePlayground)
        guard #available(macOS 15.2, *) else {
            throw BgBgOneError.frameworkError("Image Playground requires macOS 15.2+")
        }

        let holder = AsyncResultHolder()
        let semaphore = DispatchSemaphore(value: 0)
        let mapped = mappedStyle(style)
        let concepts: [ImagePlaygroundConcept] = [.text(prompt)]

        Task.detached {
            do {
                let creator = try await ImageCreator()
                let stream = creator.images(for: concepts, style: mapped, limit: 1)
                for try await item in stream {
                    holder.image = item.cgImage
                    semaphore.signal()
                    return
                }
                holder.error = BgBgOneError.frameworkError("Image Playground returned no images for prompt")
                semaphore.signal()
            } catch {
                holder.error = error
                semaphore.signal()
            }
        }
        semaphore.wait()

        if let e = holder.error {
            if let bg = e as? BgBgOneError { throw bg }
            throw BgBgOneError.frameworkError("Image Playground generation failed: \(e.localizedDescription)")
        }
        guard let img = holder.image else {
            throw BgBgOneError.frameworkError("Image Playground produced no image")
        }
        _ = size
        return img
        #else
        throw BgBgOneError.frameworkError("ImagePlayground framework not available in this SDK")
        #endif
    }

    #if canImport(ImagePlayground)
    @available(macOS 15.2, *)
    private static func mappedStyle(_ style: GenStyle) -> ImagePlaygroundStyle {
        switch style {
        case .illustration: return .illustration
        case .sketch:       return .sketch
        case .animation:    return .animation
        case .auto:         return .illustration
        }
    }
    #endif
}

/// Mutable holder used to bridge async results back into a sync caller via semaphore.
/// `@unchecked Sendable` is correct here: the semaphore wait happens-after the Task write,
/// so there is no concurrent access.
private final class AsyncResultHolder: @unchecked Sendable {
    var image: CGImage?
    var error: Error?
}
