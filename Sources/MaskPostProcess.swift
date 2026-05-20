import Foundation
import CoreGraphics
import CoreImage
import BgBgOneCore

/// Post-mask transformations applied between mask generation and final compositing.
enum MaskPostProcess {

    /// Soften the alpha matte edges. Operates on the alpha channel of a CGImage.
    static func feather(_ image: CGImage, radius: Double) -> CGImage {
        if radius <= 0 { return image }
        let ci = CIImage(cgImage: image)
        guard let filter = CIFilter(name: "CIGaussianBlur") else { return image }
        filter.setValue(ci, forKey: kCIInputImageKey)
        filter.setValue(NSNumber(value: radius), forKey: kCIInputRadiusKey)
        guard let blurred = filter.outputImage else { return image }
        // Clamp back to the original extent so the canvas size doesn't drift due to blur halo
        let cropped = blurred.cropped(to: ci.extent)
        let ctx = CIContext()
        return ctx.createCGImage(cropped, from: ci.extent) ?? image
    }

    /// Compute the smallest rect that contains all non-transparent pixels.
    /// Returns the input rect if the image has no alpha or no opaque pixels.
    static func subjectBoundingBox(_ image: CGImage) -> CGRect {
        let w = image.width
        let h = image.height
        guard let data = image.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data),
              image.bitsPerPixel == 32,
              image.bitsPerComponent == 8 else {
            return CGRect(x: 0, y: 0, width: w, height: h)
        }
        let bpr = image.bytesPerRow
        // RGBA premultipliedLast: alpha at byte offset 3 per pixel.
        var minX = w, minY = h, maxX = -1, maxY = -1
        for y in 0..<h {
            let row = bytes.advanced(by: y * bpr)
            for x in 0..<w {
                let alpha = row[x * 4 + 3]
                if alpha > 8 {
                    if x < minX { minX = x }
                    if x > maxX { maxX = x }
                    if y < minY { minY = y }
                    if y > maxY { maxY = y }
                }
            }
        }
        if maxX < 0 { return CGRect(x: 0, y: 0, width: w, height: h) }
        return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
    }

    /// Crop a CGImage to the given rect (in pixel coordinates from top-left).
    static func crop(_ image: CGImage, to rect: CGRect) -> CGImage {
        let w = image.width
        let h = image.height
        // Convert top-left rect to CoreGraphics' bottom-left rect.
        let cgRect = CGRect(
            x: rect.origin.x,
            y: CGFloat(h) - rect.origin.y - rect.size.height,
            width: rect.size.width,
            height: rect.size.height
        )
        let safeRect = cgRect.intersection(CGRect(x: 0, y: 0, width: w, height: h))
        if safeRect.isNull || safeRect.isEmpty { return image }
        return image.cropping(to: safeRect) ?? image
    }
}
