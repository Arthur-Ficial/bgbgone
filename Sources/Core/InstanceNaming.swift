import Foundation

public enum InstanceNaming {
    /// Expand a filename template with `{base}`, `{n}`, `{n:NNN}` (zero-padded), and `{ext}` tokens.
    public static func expand(template: String, base: String, n: Int, ext: String) -> String {
        var out = template
        // {n:PAD} — match width N. Manual scan to avoid regex dependency.
        while let r = out.range(of: "{n:") {
            guard let closer = out.range(of: "}", range: r.upperBound..<out.endIndex) else { break }
            let widthSpec = out[r.upperBound..<closer.lowerBound]
            let width = Int(widthSpec) ?? 0
            let replaced = String(format: "%0\(width)d", n)
            out.replaceSubrange(r.lowerBound..<closer.upperBound, with: replaced)
        }
        out = out.replacingOccurrences(of: "{base}", with: base)
        out = out.replacingOccurrences(of: "{n}", with: "\(n)")
        out = out.replacingOccurrences(of: "{ext}", with: ext)
        return out
    }
}
