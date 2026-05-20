// Linear RGBA, 0...1 doubles. Used by the colour parser and background compositor.
// Lives in BgBgOneCore so it's testable without CoreImage.

public struct RGBA: Equatable, Sendable {
    public let r: Double
    public let g: Double
    public let b: Double
    public let a: Double

    public init(r: Double, g: Double, b: Double, a: Double = 1.0) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
}
