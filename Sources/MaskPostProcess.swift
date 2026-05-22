import Foundation
import CoreGraphics
import CoreImage
import BgBgOneCore

/// Post-mask transformations applied between mask generation and final compositing.
enum MaskPostProcess {
    private static let ciContext = CIContext(options: [.cacheIntermediates: false])

    static func process(mask: CGImage, threshold: Double?, feather: Double) throws -> CGImage {
        var out = mask
        if feather > 0.001 {
            out = try featherMask(out, radius: feather)
        }
        if let threshold {
            out = try thresholdMask(out, threshold: threshold)
        }
        return out
    }

    /// Soften only the matte, not the foreground RGB pixels.
    ///
    /// Two correctness traps to be careful of:
    ///   1. CIGaussianBlur's output extent is infinite; we crop back to the source.
    ///   2. `CGContext.clip(to:mask:)` only treats the input as an alpha mask when
    ///      it is in DeviceGray colour space with no alpha channel. CIImage round-trips
    ///      default to sRGB, which silently breaks downstream clipping (the bg never
    ///      gets removed). Rasterise into an explicit DeviceGray context to lock the
    ///      colour space.
    static func featherMask(_ mask: CGImage, radius: Double) throws -> CGImage {
        if radius <= 0 { return mask }
        let ci = CIImage(cgImage: mask)
        guard let filter = CIFilter(name: "CIGaussianBlur") else {
            throw BgBgOneError.frameworkError("Core Image Gaussian blur filter is unavailable")
        }
        filter.setValue(ci, forKey: kCIInputImageKey)
        filter.setValue(NSNumber(value: radius), forKey: kCIInputRadiusKey)
        guard let blurred = filter.outputImage else {
            throw BgBgOneError.frameworkError("Core Image Gaussian blur produced no mask")
        }
        let cropped = blurred.cropped(to: ci.extent)
        guard let blurredCG = ciContext.createCGImage(cropped, from: ci.extent) else {
            throw BgBgOneError.frameworkError("cannot render feathered mask")
        }
        return try forceGrayscale(blurredCG)
    }

    /// Re-draw `image` into an 8-bit DeviceGray context.
    /// This is the colour-space normalisation the clip-as-alpha-mask path requires.
    private static func forceGrayscale(_ image: CGImage) throws -> CGImage {
        let w = image.width
        let h = image.height
        let cs = CGColorSpaceCreateDeviceGray()
        guard let ctx = CGContext(
            data: nil,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w,
            space: cs,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            throw BgBgOneError.frameworkError("cannot create grayscale mask context")
        }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        guard let out = ctx.makeImage() else {
            throw BgBgOneError.frameworkError("cannot create grayscale mask image")
        }
        return out
    }

    static func thresholdMask(_ mask: CGImage, threshold: Double) throws -> CGImage {
        let normalizedThreshold = UInt8((max(0, min(1, threshold)) * 255.0).rounded())
        var bytes = try grayscaleBytes(mask)
        for i in bytes.indices {
            bytes[i] = bytes[i] >= normalizedThreshold ? 255 : 0
        }
        return try makeGrayImage(width: mask.width, height: mask.height, bytes: bytes)
    }

    static func applyROI(_ roi: ServerRectSpec, to mask: CGImage) throws -> CGImage {
        let w = mask.width
        let h = mask.height
        var bytes = try grayscaleBytes(mask)
        let rect = CGRect(
            x: roi.x1.resolve(total: Double(w)),
            y: roi.y1.resolve(total: Double(h)),
            width: roi.x2.resolve(total: Double(w)) - roi.x1.resolve(total: Double(w)),
            height: roi.y2.resolve(total: Double(h)) - roi.y1.resolve(total: Double(h))
        ).integral
        let bounds = CGRect(x: 0, y: 0, width: w, height: h)
        let safe = rect.intersection(bounds)
        if safe.isNull || safe.isEmpty {
            throw ServerAPIError.invalid("roi_region_empty", "ROI region is empty", detail: "The given roi parameter defines an empty region")
        }
        if !bounds.contains(rect) {
            throw ServerAPIError.invalid("roi_exceeds_bounds", "ROI exceeds image bounds", detail: "The given roi parameter defines a region that exceeds the image bounds")
        }

        for y in 0..<h {
            let row = y * w
            for x in 0..<w where !safe.contains(CGPoint(x: x, y: y)) {
                bytes[row + x] = 0
            }
        }
        return try makeGrayImage(width: w, height: h, bytes: bytes)
    }

    /// Apply a grayscale mask as alpha to the original image, preserving sharp foreground pixels.
    static func apply(mask: CGImage, to image: CGImage) throws -> CGImage {
        let w = image.width
        let h = image.height
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: cs,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw BgBgOneError.frameworkError("cannot create masked foreground context")
        }

        let rect = CGRect(x: 0, y: 0, width: w, height: h)
        ctx.clear(rect)
        ctx.saveGState()
        ctx.clip(to: rect, mask: mask)
        ctx.draw(image, in: rect)
        ctx.restoreGState()

        guard let out = ctx.makeImage() else {
            throw BgBgOneError.frameworkError("cannot apply alpha mask")
        }
        return out
    }

    static func subjectBoundingBox(fromMask mask: CGImage) throws -> CGRect {
        let w = mask.width
        let h = mask.height
        let bytes = try grayscaleBytes(mask)

        var minX = w
        var minY = h
        var maxX = -1
        var maxY = -1
        for y in 0..<h {
            let row = y * w
            for x in 0..<w {
                if bytes[row + x] > 8 {
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

    static func paddedRect(_ rect: CGRect, in imageSize: CGSize, padding: Double?, isPercent: Bool) -> CGRect {
        guard let padding else { return rect }
        let padPixels: CGFloat
        if isPercent {
            padPixels = max(rect.width, rect.height) * CGFloat(padding)
        } else {
            padPixels = CGFloat(padding)
        }

        let expanded = rect.insetBy(dx: -padPixels, dy: -padPixels)
        return expanded.intersection(CGRect(origin: .zero, size: imageSize))
    }

    static func paddedRect(_ rect: CGRect, in imageSize: CGSize, margins: ServerEdgeInsets?) -> CGRect {
        guard let margins else { return rect }
        let top = clampedMargin(margins.top, total: Double(rect.height))
        let right = clampedMargin(margins.right, total: Double(rect.width))
        let bottom = clampedMargin(margins.bottom, total: Double(rect.height))
        let left = clampedMargin(margins.left, total: Double(rect.width))
        let expanded = CGRect(
            x: rect.minX - left,
            y: rect.minY - top,
            width: rect.width + left + right,
            height: rect.height + top + bottom
        )
        return expanded.intersection(CGRect(origin: .zero, size: imageSize))
    }

    private static func clampedMargin(_ value: ServerDimension, total: Double) -> CGFloat {
        let resolved = value.resolve(total: total)
        return CGFloat(max(0, min(resolved, min(500, total * 0.5))))
    }

    /// Crop a CGImage to the given rect in top-left pixel coordinates.
    static func crop(_ image: CGImage, to rect: CGRect) throws -> CGImage {
        let w = image.width
        let h = image.height
        let safeRect = rect.integral.intersection(CGRect(x: 0, y: 0, width: w, height: h))
        if safeRect.isNull || safeRect.isEmpty {
            throw BgBgOneError.frameworkError("cannot crop image to an empty rectangle")
        }
        guard let cropped = image.cropping(to: safeRect) else {
            throw BgBgOneError.frameworkError("cannot crop image")
        }
        return cropped
    }

    private static func grayscaleBytes(_ image: CGImage) throws -> [UInt8] {
        let w = image.width
        let h = image.height
        var bytes = [UInt8](repeating: 0, count: w * h)
        let cs = CGColorSpaceCreateDeviceGray()
        try bytes.withUnsafeMutableBytes { raw in
            guard let base = raw.baseAddress,
                  let ctx = CGContext(
                    data: base,
                    width: w,
                    height: h,
                    bitsPerComponent: 8,
                    bytesPerRow: w,
                    space: cs,
                    bitmapInfo: CGImageAlphaInfo.none.rawValue
                  ) else {
                throw BgBgOneError.frameworkError("cannot create grayscale mask context")
            }
            ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        return bytes
    }

    private static func makeGrayImage(width: Int, height: Int, bytes: [UInt8]) throws -> CGImage {
        let data = Data(bytes)
        guard let provider = CGDataProvider(data: data as CFData) else {
            throw BgBgOneError.frameworkError("cannot create mask data provider")
        }
        let cs = CGColorSpaceCreateDeviceGray()
        guard let image = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: width,
            space: cs,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else {
            throw BgBgOneError.frameworkError("cannot create thresholded mask image")
        }
        return image
    }
}
