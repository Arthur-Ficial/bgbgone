import Foundation

public enum OutputFormat: String, Sendable, Equatable {
    case png
    case jpeg = "jpg"
    case webp
    case heic
    case avif
    case tiff
}

public enum OutputMode: Sendable, Equatable {
    case standard
    case json
    case ndjson
}

public enum Background: Sendable, Equatable {
    case transparent
    case solidColor(RGBA)
    case image(String)            // path
}

public enum Algo: String, Sendable, Equatable {
    case auto
    case vnRemove = "vn-remove"
    case vnMask = "vn-mask"
    case person
    case sky
    case saliency
}

public enum BgFit: String, Sendable, Equatable {
    case cover
    case contain
    case tile
    case center
}

public struct Config: Sendable, Equatable {
    public enum Mode: Sendable, Equatable {
        case helpRequested
        case versionRequested
        case capabilityCheckRequested
        case process
    }

    public var mode: Mode
    public var inputs: [String]
    public var output: String?
    public var outputDir: String?
    public var outputFormat: OutputFormat
    public var quality: Int
    public var background: Background
    public var bgFit: BgFit
    public var algo: Algo
    public var maskOnly: Bool
    public var feather: Double
    public var threshold: Double?
    public var padding: Double?           // px; percentage stored as 0..1
    public var cropToSubject: Bool
    public var dropShadow: Bool
    public var multiInstance: Bool
    public var instanceNamingTemplate: String
    public var outputMode: OutputMode
    public var quiet: Bool
    public var verbose: Bool

    public init(mode: Mode = .helpRequested) {
        self.mode = mode
        self.inputs = []
        self.output = nil
        self.outputDir = nil
        self.outputFormat = .png
        self.quality = 92
        self.background = .transparent
        self.bgFit = .cover
        self.algo = .auto
        self.maskOnly = false
        self.feather = 1.0
        self.threshold = nil
        self.padding = nil
        self.cropToSubject = false
        self.dropShadow = false
        self.multiInstance = false
        self.instanceNamingTemplate = "{base}-{n}.{ext}"
        self.outputMode = .standard
        self.quiet = false
        self.verbose = false
    }
}
