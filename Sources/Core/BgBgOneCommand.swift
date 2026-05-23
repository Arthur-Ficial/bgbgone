import Foundation
import ArgumentParser

/// The swift-argument-parser surface for the bgbgone CLI. Holds raw typed flags
/// only. Cross-cutting resolution (mode, autoFileOutput, env vars, validation)
/// lives in `ConfigBuilder.build(...)` because it needs TTY signals the parser
/// itself does not know about.
public struct BgBgOneCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "bgbgone",
        abstract: "UNIX-style background remover for macOS (100% on-device).",
        // Disable swift-argument-parser's built-in --help/-h - bgbgone prints its
        // own rich help via CLI.printHelp(), routed through main.swift after
        // we see one of the mode flags below.
        helpNames: []
    )

    // Mode flags - main.swift checks these first and routes to CLI helpers.
    @Flag(name: .customLong("version")) public var version: Bool = false
    @Flag(name: [.customLong("help"), .customShort("h")]) public var help: Bool = false
    @Flag(name: .customLong("check")) public var check: Bool = false
    @Flag(name: .customLong("server")) public var server: Bool = false

    // Server options (recognised even outside --server; ConfigBuilder catches misuse)
    @Option(name: .customLong("host")) public var host: String?
    @Option(name: .customLong("port")) public var port: Int?
    @Flag(name: .customLong("cors")) public var cors: Bool = false
    @Option(name: .customLong("allowed-origins")) public var allowedOrigins: String?
    @Flag(name: .customLong("no-origin-check")) public var noOriginCheck: Bool = false
    @Option(name: .customLong("token")) public var token: String?
    @Flag(name: .customLong("token-auto")) public var tokenAuto: Bool = false
    @Flag(name: .customLong("public-health")) public var publicHealth: Bool = false
    @Option(name: .customLong("max-body-mb")) public var maxBodyMb: Int?
    @Flag(name: .customLong("footgun")) public var footgun: Bool = false

    // Output
    @Option(name: [.customShort("o"), .customLong("output")]) public var output: String?
    @Option(name: .customLong("out-dir")) public var outDir: String?
    @Option(name: [.customLong("to"), .customLong("format")]) public var outputFormatRaw: String?
    @Option(name: .customLong("size")) public var size: String?
    @Option(name: .customLong("quality")) public var quality: Int?

    // Background
    @Option(name: .customLong("bg")) public var bg: String?
    @Option(name: .customLong("bg-color")) public var bgColor: String?
    @Option(name: .customLong("bg-image")) public var bgImage: String?
    @Option(name: .customLong("bg-fit")) public var bgFit: String?

    // Matte / edge
    @Flag(name: .customLong("mask-only")) public var maskOnly: Bool = false
    @Option(name: .customLong("channels")) public var channels: String?
    @Option(name: .customLong("feather")) public var feather: Double?
    @Option(name: .customLong("threshold")) public var threshold: Double?
    @Option(name: .customLong("padding")) public var padding: String?
    @Option(name: .customLong("crop-margin")) public var cropMargin: String?
    @Flag(name: .customLong("crop")) public var crop: Bool = false
    @Option(name: .customLong("roi")) public var roi: String?
    @Option(name: .customLong("scale")) public var scale: String?
    @Option(name: .customLong("position")) public var position: String?
    @Option(name: .customLong("semitransparency")) public var semitransparency: String?

    // Algorithm
    @Option(name: .customLong("algo")) public var algo: String?
    @Option(name: .customLong("type")) public var type: String?

    // Multi-instance
    @Flag(name: .customLong("multi")) public var multi: Bool = false
    @Option(name: .customLong("instance-naming")) public var instanceNaming: String?

    // Shadow
    @Flag(name: .customLong("shadow")) public var shadow: Bool = false
    @Option(name: .customLong("shadow-type")) public var shadowType: String?
    @Option(name: .customLong("shadow-opacity")) public var shadowOpacity: String?

    // Output mode (mutex enforced in ConfigBuilder)
    @Flag(name: .customLong("json")) public var json: Bool = false
    @Flag(name: .customLong("ndjson")) public var ndjson: Bool = false
    @Flag(name: .customLong("quiet")) public var quiet: Bool = false
    @Flag(name: .customLong("verbose")) public var verbose: Bool = false

    // Positional inputs (paths or "-" for stdin)
    @Argument(parsing: .remaining) public var inputs: [String] = []

    public init() {}
}
