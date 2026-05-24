import Foundation
import ArgumentParser

/// Bridges a parsed `BgBgOneCommand` to a fully-resolved `Config`.
public enum ConfigBuilder {

    public static func build(
        cmd: BgBgOneCommand,
        isStdinTTY: Bool,
        isStdoutTTY: Bool,
        stdoutPath: String?,
        environment: [String: String]
    ) throws -> Config {
        var cfg = Config()
        applyEnvironment(into: &cfg, environment)

        let mode = explicitMode(cmd)
        try applyServerFlags(cmd, into: &cfg)
        let sawProcessingOption = try applyProcessingFlags(cmd, into: &cfg)
        let explicitOutputFormat = cmd.outputFormatRaw != nil || cmd.channels?.lowercased() == "alpha"

        cfg.inputs = cmd.inputs

        if let m = mode {
            try applyExplicitMode(m, cmd: cmd, cfg: &cfg, sawProcessingOption: sawProcessingOption)
            if cfg.mode != .process { return cfg }
        } else if sawServerOnlyFlag(cmd) {
            throw BgBgOneError.userError(
                ErrorCodes.parseFlagDuplicate,
                "server options require --server",
                hint: "add --server or remove the server-only flags"
            )
        }
        if cfg.mode == .helpRequested && mode == nil { /* will be re-resolved below */ }

        try resolveInputsAndMode(cmd: cmd, cfg: &cfg, isStdinTTY: isStdinTTY, sawProcessingOption: sawProcessingOption)
        if cfg.mode != .process { return cfg }

        try resolveOutputFormat(cfg: &cfg, isStdoutTTY: isStdoutTTY, stdoutPath: stdoutPath, explicitFormat: explicitOutputFormat)
        try resolveAutoFileOutput(cfg: &cfg, isStdoutTTY: isStdoutTTY)
        try resolveSize(rawSize: cmd.size, cfg: &cfg)
        try validate(cfg, isStdoutTTY: isStdoutTTY)
        return cfg
    }

    // MARK: env

    private static func applyEnvironment(into cfg: inout Config, _ env: [String: String]) {
        cfg.server.token = env["BGBGONE_TOKEN"].flatMap { $0.isEmpty ? nil : $0 }
        if let host = env["BGBGONE_HOST"], !host.isEmpty { cfg.server.host = host }
        if let port = env["BGBGONE_PORT"], let n = Int(port), (1...65535).contains(n) { cfg.server.port = n }
    }

    // MARK: mode

    private static func explicitMode(_ cmd: BgBgOneCommand) -> Config.Mode? {
        if cmd.version { return .versionRequested }
        if cmd.help    { return .helpRequested }
        if cmd.check   { return .capabilityCheckRequested }
        if cmd.filtersList { return .filtersListRequested }
        if cmd.server  { return .serverRequested }
        return nil
    }

    private static func applyExplicitMode(
        _ mode: Config.Mode,
        cmd: BgBgOneCommand,
        cfg: inout Config,
        sawProcessingOption: Bool
    ) throws {
        cfg.mode = mode
        guard mode == .serverRequested else { return }
        if sawProcessingOption {
            throw BgBgOneError.userError(
                ErrorCodes.parseFlagDuplicate,
                "--server cannot be combined with image-processing options",
                hint: "drop the image-processing flags or omit --server"
            )
        }
        if !cmd.inputs.isEmpty {
            throw BgBgOneError.userError(
                ErrorCodes.parseFlagDuplicate,
                "--server does not accept image input arguments; send images to the HTTP API"
            )
        }
    }

    private static func sawServerOnlyFlag(_ cmd: BgBgOneCommand) -> Bool {
        cmd.host != nil || cmd.port != nil || cmd.cors || cmd.allowedOrigins != nil ||
        cmd.noOriginCheck || cmd.token != nil || cmd.tokenAuto || cmd.publicHealth ||
        cmd.maxBodyMb != nil || cmd.footgun
    }

    // MARK: input + mode resolution

    private static func resolveInputsAndMode(
        cmd: BgBgOneCommand,
        cfg: inout Config,
        isStdinTTY: Bool,
        sawProcessingOption: Bool
    ) throws {
        if cfg.inputs.isEmpty {
            if !isStdinTTY {
                cfg.inputs = ["-"]
                cfg.mode = .process
            } else if sawProcessingOption {
                throw BgBgOneError.userError(
                    ErrorCodes.userInputCountMismatch,
                    "no input provided",
                    hint: "pass one or more image paths, or pipe an image into stdin"
                )
            } else {
                cfg.mode = .helpRequested
            }
        } else {
            cfg.mode = .process
        }
    }

    // MARK: output format inference

    private static func resolveOutputFormat(
        cfg: inout Config,
        isStdoutTTY: Bool,
        stdoutPath: String?,
        explicitFormat: Bool
    ) throws {
        if explicitFormat { return }
        if let output = cfg.output, let inferred = OutputFormat.fromFileExtension(output) {
            cfg.outputFormat = inferred
        } else if cfg.output == nil,
                  cfg.outputDir == nil,
                  cfg.outputMode == .standard,
                  !isStdoutTTY,
                  cfg.inputs.count == 1,
                  let stdoutPath,
                  let inferred = OutputFormat.fromFileExtension(stdoutPath) {
            cfg.outputFormat = inferred
        }
    }

    private static func resolveAutoFileOutput(cfg: inout Config, isStdoutTTY: Bool) throws {
        guard cfg.mode == .process, cfg.output == nil, cfg.outputDir == nil else { return }
        let canDeriveFileOutput = !cfg.inputs.isEmpty && cfg.inputs.allSatisfy { $0 != "-" }
        if cfg.outputMode != .standard {
            if canDeriveFileOutput { cfg.autoFileOutput = true; return }
            throw BgBgOneError.userError(
                ErrorCodes.userOutputPathInvalid,
                "--json/--ndjson requires -o or --out-dir when reading image data from stdin",
                hint: "add -o <file> or --out-dir <dir>"
            )
        } else if isStdoutTTY {
            if canDeriveFileOutput { cfg.autoFileOutput = true; return }
            throw BgBgOneError.userError(
                ErrorCodes.userStdoutTTYRefuse,
                "refusing to write binary image data to a terminal. Use -o <file>, --out-dir <dir>, or pipe to a file.",
                hint: "redirect stdout or pass -o/--out-dir"
            )
        } else if cfg.inputs.count > 1 && canDeriveFileOutput {
            cfg.autoFileOutput = true
        }
    }

    private static func resolveSize(rawSize: String?, cfg: inout Config) throws {
        guard let raw = rawSize else { return }
        cfg.maxOutputMegapixels = try mapParameterParserError("--size", code: ErrorCodes.parseFlagValueInvalid) {
            try ParameterParser.parseSize(raw, outputFormat: cfg.outputFormat)
        }
    }

    static func mapParameterParserError<T>(_ origin: String, code: String, _ block: () throws -> T) throws -> T {
        do { return try block() } catch let e as ParameterParseError {
            var context: [String: String] = ["field_code": e.code]
            if let detail = e.detail, !detail.isEmpty {
                context["detail"] = detail
            }
            throw BgBgOneError.parser(code, e.message, origin: origin, context: context)
        }
    }
}
