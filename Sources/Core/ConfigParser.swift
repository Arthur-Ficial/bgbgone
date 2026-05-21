import Foundation

public enum ConfigParser {

    /// Parse argv (excluding argv[0]) into a Config, with explicit stdin/stdout TTY signals so
    /// the parser stays pure (tests don't need to spawn processes to flip those bits).
    public static func parse(
        args: [String],
        isStdinTTY: Bool,
        isStdoutTTY: Bool,
        stdoutPath: String? = nil
    ) throws -> Config {
        var cfg = Config()

        // Walk args. Anything starting with `-` is a flag until `--`; anything after `--`
        // is a positional input, including filenames that start with a dash.
        var i = 0
        var sawProcessingOption = false

        // Track whether the user explicitly asked for a non-process mode.
        var explicitMode: Config.Mode?
        var explicitOutputFormat = false
        var outputModeFlag: String?
        var sawQuiet = false
        var sawVerbose = false

        while i < args.count {
            let a = args[i]
            switch a {
            case "--":
                cfg.inputs.append(contentsOf: args[(i + 1)...])
                sawProcessingOption = sawProcessingOption || !cfg.inputs.isEmpty
                i = args.count
            case "--version":
                explicitMode = .versionRequested
                i += 1
            case "--help", "-h":
                explicitMode = .helpRequested
                i += 1
            case "--check":
                explicitMode = .capabilityCheckRequested
                i += 1
            case "-o", "--output":
                sawProcessingOption = true
                cfg.output = try takeValue(args, &i, flag: a)
            case "--out-dir":
                sawProcessingOption = true
                cfg.outputDir = try takeValue(args, &i, flag: a)
            case "--to":
                sawProcessingOption = true
                let v = try takeValue(args, &i, flag: a)
                guard let f = OutputFormat.parse(v) else {
                    throw BgBgOneError.parser("unknown --to value: \(v) (allowed: png, jpg/jpeg, heic, avif, tiff)")
                }
                cfg.outputFormat = f
                explicitOutputFormat = true
            case "--quality":
                sawProcessingOption = true
                let v = try takeValue(args, &i, flag: a)
                guard let n = Int(v), (1...100).contains(n) else {
                    throw BgBgOneError.parser("--quality must be 1..100, got: \(v)")
                }
                cfg.quality = n
            case "--bg":
                sawProcessingOption = true
                cfg.background = try parseBackground(try takeValue(args, &i, flag: a))
            case "--bg-fit":
                sawProcessingOption = true
                let v = try takeValue(args, &i, flag: a)
                guard let f = BgFit(rawValue: v) else {
                    throw BgBgOneError.parser("unknown --bg-fit value: \(v) (allowed: cover, contain, tile, center)")
                }
                cfg.bgFit = f
            case "--algo":
                sawProcessingOption = true
                let v = try takeValue(args, &i, flag: a)
                guard let f = Algo(rawValue: v) else {
                    throw BgBgOneError.parser("unknown --algo value: \(v) (allowed: auto, vn-mask, person, saliency)")
                }
                cfg.algo = f
            case "--mask-only":
                sawProcessingOption = true
                cfg.maskOnly = true
                i += 1
            case "--feather":
                sawProcessingOption = true
                let v = try takeValue(args, &i, flag: a)
                guard let n = Double(v), n >= 0 else {
                    throw BgBgOneError.parser("--feather must be a non-negative number, got: \(v)")
                }
                cfg.feather = n
            case "--threshold":
                sawProcessingOption = true
                let v = try takeValue(args, &i, flag: a)
                guard let n = Double(v), (0...1).contains(n) else {
                    throw BgBgOneError.parser("--threshold must be 0..1, got: \(v)")
                }
                cfg.threshold = n
            case "--padding":
                sawProcessingOption = true
                let v = try takeValue(args, &i, flag: a)
                let parsed = try parsePadding(v)
                cfg.padding = parsed.value
                cfg.paddingIsPercent = parsed.isPercent
            case "--crop":
                sawProcessingOption = true
                cfg.cropToSubject = true
                i += 1
            case "--shadow":
                sawProcessingOption = true
                cfg.dropShadow = true
                i += 1
            case "--multi":
                sawProcessingOption = true
                cfg.multiInstance = true
                i += 1
            case "--instance-naming":
                sawProcessingOption = true
                cfg.instanceNamingTemplate = try takeValue(args, &i, flag: a)
            case "--json":
                if let outputModeFlag, outputModeFlag != a {
                    throw BgBgOneError.userError("--json and --ndjson are mutually exclusive")
                }
                outputModeFlag = a
                sawProcessingOption = true
                cfg.outputMode = .json
                i += 1
            case "--ndjson":
                if let outputModeFlag, outputModeFlag != a {
                    throw BgBgOneError.userError("--json and --ndjson are mutually exclusive")
                }
                outputModeFlag = a
                sawProcessingOption = true
                cfg.outputMode = .ndjson
                i += 1
            case "--quiet":
                if sawVerbose {
                    throw BgBgOneError.userError("--quiet and --verbose are mutually exclusive")
                }
                sawQuiet = true
                cfg.quiet = true
                i += 1
            case "--verbose":
                if sawQuiet {
                    throw BgBgOneError.userError("--quiet and --verbose are mutually exclusive")
                }
                sawVerbose = true
                cfg.verbose = true
                i += 1
            default:
                if a.hasPrefix("-") && a != "-" {
                    throw BgBgOneError.parser("unknown option: \(a)")
                }
                cfg.inputs.append(a)
                i += 1
            }
        }

        // Mode resolution
        if let m = explicitMode {
            cfg.mode = m
            return cfg
        }

        if cfg.inputs.isEmpty {
            if !isStdinTTY {
                // Piped input
                cfg.inputs = ["-"]
                cfg.mode = .process
            } else if sawProcessingOption {
                throw BgBgOneError.userError("no input provided")
            } else {
                // No args, no pipe → behave like `bgbgone --help`
                cfg.mode = .helpRequested
                return cfg
            }
        } else {
            cfg.mode = .process
        }

        if !explicitOutputFormat {
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

        if cfg.mode == .process, cfg.output == nil, cfg.outputDir == nil {
            let canDeriveFileOutput = !cfg.inputs.isEmpty && cfg.inputs.allSatisfy { $0 != "-" }
            if cfg.outputMode != .standard {
                if canDeriveFileOutput {
                    cfg.autoFileOutput = true
                } else {
                    throw BgBgOneError.userError("--json/--ndjson requires -o or --out-dir when reading image data from stdin")
                }
            } else if isStdoutTTY {
                if canDeriveFileOutput {
                    cfg.autoFileOutput = true
                } else {
                    throw BgBgOneError.userError("refusing to write binary image data to a terminal. Use -o <file>, --out-dir <dir>, or pipe to a file.")
                }
            } else if cfg.inputs.count > 1 && canDeriveFileOutput {
                cfg.autoFileOutput = true
            }
        }

        try validate(cfg)
        return cfg
    }

    private static func validate(_ cfg: Config) throws {
        let readsFromStdin = cfg.inputs.contains("-")

        if cfg.output != nil && cfg.outputDir != nil {
            throw BgBgOneError.userError("use either -o/--output or --out-dir, not both")
        }

        if cfg.inputs.count > 1 && cfg.output != nil {
            throw BgBgOneError.userError("-o cannot be used with multiple inputs; use --out-dir")
        }

        if cfg.multiInstance {
            if cfg.output != nil {
                throw BgBgOneError.userError("--multi can emit multiple files; use --out-dir or omit output to write next to the input")
            }
            if cfg.maskOnly {
                throw BgBgOneError.userError("--multi and --mask-only are mutually exclusive")
            }
            if readsFromStdin {
                throw BgBgOneError.userError("--multi cannot read from stdin because instance filenames need a file input stem")
            }
        }

        if readsFromStdin && cfg.outputDir != nil {
            throw BgBgOneError.userError("stdin input has no output filename; use -o <file> instead of --out-dir")
        }
    }

    private static func takeValue(_ args: [String], _ i: inout Int, flag: String) throws -> String {
        guard i + 1 < args.count else {
            throw BgBgOneError.parser("\(flag) requires a value")
        }
        i += 2
        return args[i - 1]
    }

    private static func parseBackground(_ spec: String) throws -> Background {
        if let v = spec.dropPrefixIfMatches("color:") {
            return .solidColor(try ColourParser.parse(v))
        }
        if let v = spec.dropPrefixIfMatches("image:") {
            return .image(v)
        }
        throw BgBgOneError.parser("--bg must be color:<spec> or image:<path>, got: \(spec)")
    }

    private static func parsePadding(_ raw: String) throws -> (value: Double, isPercent: Bool) {
        if raw.hasSuffix("%") {
            let body = String(raw.dropLast())
            guard let n = Double(body), n >= 0 else {
                throw BgBgOneError.parser("invalid --padding percent: \(raw)")
            }
            return (n / 100.0, true)
        }
        guard let n = Double(raw), n >= 0 else {
            throw BgBgOneError.parser("invalid --padding: \(raw)")
        }
        return (n, false)
    }
}

private extension String {
    func dropPrefixIfMatches(_ prefix: String) -> String? {
        guard hasPrefix(prefix) else { return nil }
        return String(dropFirst(prefix.count))
    }
}
