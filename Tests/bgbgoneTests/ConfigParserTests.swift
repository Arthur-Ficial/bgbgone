import Foundation
import BgBgOneCore

func runConfigParserTests() {
    test("parses no args -> .helpRequested when stdin is TTY") {
        let cfg = try ConfigParser.parse(args: [], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.mode, .helpRequested)
    }

    test("--version sets versionRequested") {
        let cfg = try ConfigParser.parse(args: ["--version"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.mode, .versionRequested)
    }

    test("--help sets helpRequested") {
        let cfg = try ConfigParser.parse(args: ["--help"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.mode, .helpRequested)
    }

    test("-h sets helpRequested") {
        let cfg = try ConfigParser.parse(args: ["-h"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.mode, .helpRequested)
    }

    test("--check sets capabilityCheckRequested") {
        let cfg = try ConfigParser.parse(args: ["--check"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.mode, .capabilityCheckRequested)
    }

    test("processing flags without an input are rejected instead of showing help") {
        do {
            _ = try ConfigParser.parse(args: ["-o", "out.png"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if e.category == .user {
                let message = e.message
                try assertTrue(message.contains("input"))
            } else {
                throw TestFailure("wrong error: \(e)")
            }
        }
    }

    test("single positional input becomes inputs[0]") {
        let cfg = try ConfigParser.parse(args: ["in.jpg"], isStdinTTY: true, isStdoutTTY: false)
        try assertEqual(cfg.mode, .process)
        try assertEqual(cfg.inputs.count, 1)
        try assertEqual(cfg.inputs[0], "in.jpg")
    }

    test("multiple positionals become batch inputs") {
        let cfg = try ConfigParser.parse(args: ["a.jpg", "b.jpg", "c.jpg"], isStdinTTY: true, isStdoutTTY: false)
        try assertEqual(cfg.inputs.count, 3)
        try assertEqual(cfg.inputs[2], "c.jpg")
    }

    test("-- stops option parsing so dash-prefixed filenames are valid inputs") {
        let cfg = try ConfigParser.parse(args: ["--", "-portrait.jpg"], isStdinTTY: true, isStdoutTTY: false)
        try assertEqual(cfg.mode, .process)
        try assertEqual(cfg.inputs, ["-portrait.jpg"])
    }

    test("-- can appear after flags before dash-prefixed inputs") {
        let cfg = try ConfigParser.parse(args: ["--format", "jpg", "--", "-portrait.png"], isStdinTTY: true, isStdoutTTY: false)
        try assertEqual(cfg.outputFormat, .jpeg)
        try assertEqual(cfg.inputs, ["-portrait.png"])
    }

    test("-o sets output path") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out.png"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.output, "out.png")
    }

    test("-o infers jpg format from output extension") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out.jpg"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.output, "out.jpg")
        try assertEqual(cfg.outputFormat, .jpeg)
    }

    test("-o infers jpeg format from long extension") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out.jpeg"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.outputFormat, .jpeg)
    }

    test("explicit --format wins over output extension") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out.jpg", "--format", "png"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.outputFormat, .png)
    }

    test("stdout redirection path infers output format when shell exposes it") {
        let cfg = try ConfigParser.parse(
            args: ["in.jpg"],
            isStdinTTY: true,
            isStdoutTTY: false,
            stdoutPath: "/tmp/cutout.jpg"
        )
        try assertEqual(cfg.outputFormat, .jpeg)
    }

    test("--output sets output path") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "--output", "out.png"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.output, "out.png")
    }

    test("--out-dir sets outputDir") {
        let cfg = try ConfigParser.parse(args: ["a.jpg", "b.jpg", "--out-dir", "./out/"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.outputDir, "./out/")
    }

    test("-o and --out-dir are rejected together because output routing must be unambiguous") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out.png", "--out-dir", "./out"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if e.category == .user {
                let message = e.message
                try assertTrue(message.contains("-o") && message.contains("--out-dir"))
            } else {
                throw TestFailure("wrong error: \(e)")
            }
        }
    }

    test("multiple file inputs with -o are rejected before processing starts") {
        do {
            _ = try ConfigParser.parse(args: ["a.jpg", "b.jpg", "-o", "out.png"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if e.category == .user {
                let message = e.message
                try assertTrue(message.contains("-o") && message.contains("multiple inputs"))
            } else {
                throw TestFailure("wrong error: \(e)")
            }
        }
    }

    test("stdin input with --out-dir is rejected because no output filename can be derived") {
        do {
            _ = try ConfigParser.parse(args: ["--out-dir", "./out"], isStdinTTY: false, isStdoutTTY: false)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if e.category == .user {
                let message = e.message
                try assertTrue(message.contains("stdin") && message.contains("-o"))
            } else {
                throw TestFailure("wrong error: \(e)")
            }
        }
    }

    test("--format png sets format") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--format", "png"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.outputFormat, .png)
    }

    test("--format jpg") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--format", "jpg"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.outputFormat, .jpeg)
    }

    test("--format heic / avif / tiff") {
        try assertEqual(
            try ConfigParser.parse(args: ["in.jpg", "-o", "x", "--format", "heic"], isStdinTTY: true, isStdoutTTY: true).outputFormat,
            .heic
        )
        try assertEqual(
            try ConfigParser.parse(args: ["in.jpg", "-o", "x", "--format", "avif"], isStdinTTY: true, isStdoutTTY: true).outputFormat,
            .avif
        )
        try assertEqual(
            try ConfigParser.parse(args: ["in.jpg", "-o", "x", "--format", "tiff"], isStdinTTY: true, isStdoutTTY: true).outputFormat,
            .tiff
        )
    }

    test("--format zip is accepted as a split color-and-alpha package") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out.zip", "--format", "zip"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.outputFormat, .zip)
    }

    test("--format is the CLI spelling for the same output format contract") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out.zip", "--format", "zip"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.outputFormat, .zip)
    }

    test("--format webp is rejected (not supported by ImageIO on this SDK)") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "x", "--format", "webp"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw — webp is not supported")
        } catch let e as BgBgOneError {
            if e.category != .parser { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("--format bogus throws parser error") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--format", "bmp"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if e.category != .parser { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("--quality 80") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--quality", "80"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.quality, 80)
    }

    test("--quality default is 92") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.quality, 92)
    }

    test("--bg color:#fff parses solid colour bg") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--bg", "color:#fff"], isStdinTTY: true, isStdoutTTY: true)
        if case .solidColor(let rgba) = cfg.background {
            try assertEqual(rgba.r, 1.0)
            try assertEqual(rgba.g, 1.0)
            try assertEqual(rgba.b, 1.0)
            try assertEqual(rgba.a, 1.0)
        } else {
            throw TestFailure("expected .solidColor, got \(String(describing: cfg.background))")
        }
    }

    test("--bg-color is not a CLI alias; use --bg color:<spec>") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--bg-color", "fff"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if e.category != .parser { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("--bg image:./bg.jpg parses image bg") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--bg", "image:./bg.jpg"], isStdinTTY: true, isStdoutTTY: true)
        if case .image(let path) = cfg.background {
            try assertEqual(path, "./bg.jpg")
        } else {
            throw TestFailure("expected .image, got \(String(describing: cfg.background))")
        }
    }

    test("--bg-image is not a CLI alias; use --bg image:<path>") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--bg-image", "./bg.jpg"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if e.category != .parser { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("--bg with unknown scheme is rejected as a parser error") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--bg", "magic:sunset"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if e.category == .parser {
                let m = e.message
                try assertTrue(m.contains("--bg") && m.contains("color:") && m.contains("image:"))
            } else {
                throw TestFailure("wrong error: \(e)")
            }
        }
    }

    test("default background is .transparent (cutout)") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out"], isStdinTTY: true, isStdoutTTY: true)
        if case .transparent = cfg.background { } else {
            throw TestFailure("expected .transparent, got \(String(describing: cfg.background))")
        }
    }

    test("--algo is removed; --type is the single canonical algo selector") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--algo", "vn-mask"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw for removed --algo")
        } catch let e as BgBgOneError {
            if e.category != .parser { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("--type direct Algo names (vn-mask / person / saliency / auto) map straight through") {
        for (raw, expected): (String, Algo) in [("auto", .auto), ("vn-mask", .vnMask), ("person", .person), ("saliency", .saliency)] {
            let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--type", raw], isStdinTTY: true, isStdoutTTY: true)
            try assertEqual(cfg.algo, expected)
        }
    }

    test("--type subject hints map to local algorithms") {
        let person = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--type", "person"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(person.algo, .person)

        let product = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--type", "product"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(product.algo, .auto)
    }

    test("--type bogus throws a parser error") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--type", "magic"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if e.category != .parser { throw TestFailure("wrong error: \(e)") }
        }
    }

    // T54..T56 removals: --mask-only, --feather, --threshold, --scale, --position
    // are hard-removed from the CLI. Replacements:
    //   --filter "fg:matte"             instead of --mask-only
    //   --filter "mask:feather=N"       instead of --feather N
    //   --filter "mask:threshold=N"     instead of --threshold N
    //   --filter "fg:scale=F"           instead of --scale F
    //   --filter "fg:translate=X,Y"     instead of --position X% Y%
    // --channels is the single transport-neutral selector for image vs alpha output.

    test("--channels alpha maps to the same mask-only output as the server") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--channels", "alpha"], isStdinTTY: true, isStdoutTTY: true)
        try assertTrue(cfg.maskOnly)
        try assertEqual(cfg.outputFormat, .png)
    }

    test("--channels rgba keeps finalized image output") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--channels", "rgba"], isStdinTTY: true, isStdoutTTY: true)
        try assertFalse(cfg.maskOnly)
    }

    test("--padding is removed; use --crop-margin <single value>") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--padding", "10%"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw for removed --padding")
        } catch let e as BgBgOneError {
            if e.category != .parser { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("--crop-margin 10% replaces --padding 10%") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--crop-margin", "10%"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.cropMargins, EdgeInsetsSpec(top: .percent(0.10), right: .percent(0.10), bottom: .percent(0.10), left: .percent(0.10)))
    }

    test("--crop sets crop true") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--crop"], isStdinTTY: true, isStdoutTTY: true)
        try assertTrue(cfg.cropToSubject)
    }

    test("--shadow is removed; use --shadow-type drop") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--shadow"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw for removed --shadow")
        } catch let e as BgBgOneError {
            if e.category != .parser { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("--shadow-type drop enables the drop shadow (replaces --shadow)") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--shadow-type", "drop"], isStdinTTY: true, isStdoutTTY: true)
        try assertTrue(cfg.dropShadow)
    }

    test("advanced geometry and output sizing flags parse through shared Config") {
        let cfg = try ConfigParser.parse(
            args: [
                "in.jpg",
                "-o", "out.png",
                "--format", "jpg",
                "--size", "full",
                "--roi", "10% 20% 90% 80%",
                "--crop-margin", "10px 20px 30px 40px",
                "--semitransparency", "false",
                "--shadow-type", "drop",
                "--shadow-opacity", "25"
            ],
            isStdinTTY: true,
            isStdoutTTY: true
        )
        try assertEqual(cfg.maxOutputMegapixels, 25.0)
        try assertEqual(cfg.roi, RectSpec(x1: .percent(0.10), y1: .percent(0.20), x2: .percent(0.90), y2: .percent(0.80)))
        try assertEqual(cfg.cropMargins, EdgeInsetsSpec(top: .pixels(10), right: .pixels(20), bottom: .pixels(30), left: .pixels(40)))
        try assertFalse(cfg.semitransparency)
        try assertTrue(cfg.dropShadow)
        try assertEqual(cfg.shadowOpacity, 0.25)
    }

    test("--multi sets multiInstance true") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "--multi", "--out-dir", "out"], isStdinTTY: true, isStdoutTTY: true)
        try assertTrue(cfg.multiInstance)
    }

    test("--multi with -o is rejected because one input can produce multiple files") {
        do {
            _ = try ConfigParser.parse(args: ["team.jpg", "--multi", "-o", "person.png"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if e.category == .user {
                let message = e.message
                try assertTrue(message.contains("--multi") && message.contains("--out-dir"))
            } else {
                throw TestFailure("wrong error: \(e)")
            }
        }
    }

    test("--multi with stdin is rejected because instance filenames need a file stem") {
        do {
            _ = try ConfigParser.parse(args: ["--multi", "--out-dir", "./people"], isStdinTTY: false, isStdoutTTY: false)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if e.category == .user {
                let message = e.message
                try assertTrue(message.contains("--multi") && message.contains("stdin"))
            } else {
                throw TestFailure("wrong error: \(e)")
            }
        }
    }

    // --multi / --mask-only mutex test removed: --mask-only no longer exists (use --filter "fg:matte")
    // and --multi + --filter chains have no mutex (each instance gets the same filter chain).

    test("--json sets outputMode .json") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--json"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.outputMode, .json)
    }

    test("--json and --ndjson are rejected together") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out.png", "--json", "--ndjson"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if e.category == .user {
                let message = e.message
                try assertTrue(message.contains("--json") && message.contains("--ndjson"))
            } else {
                throw TestFailure("wrong error: \(e)")
            }
        }
    }

    test("--quiet sets quiet true") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--quiet"], isStdinTTY: true, isStdoutTTY: true)
        try assertTrue(cfg.quiet)
    }

    test("--quiet and --verbose are rejected together") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out.png", "--quiet", "--verbose"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if e.category == .user {
                let message = e.message
                try assertTrue(message.contains("--quiet") && message.contains("--verbose"))
            } else {
                throw TestFailure("wrong error: \(e)")
            }
        }
    }

    test("--bg-fit cover/contain/tile/center parses") {
        for raw in ["cover", "contain", "tile", "center"] {
            let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--bg", "image:./bg.jpg", "--bg-fit", raw], isStdinTTY: true, isStdoutTTY: true)
            try assertEqual(cfg.bgFit.rawValue, raw)
        }
    }

    test("--style is not a known flag") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--style", "sketch"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw — --style is not a recognised flag")
        } catch let e as BgBgOneError {
            if e.category != .parser { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("unknown flag throws parser error") {
        do {
            _ = try ConfigParser.parse(args: ["--made-up-flag"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if e.category != .parser { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("terminal stdout with one file input auto-selects friendly output file") {
        let cfg = try ConfigParser.parse(args: ["photo.jpg"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.mode, .process)
        try assertTrue(cfg.autoFileOutput)
        try assertNil(cfg.output)
        try assertNil(cfg.outputDir)
    }

    test("redirected stdout keeps binary stdout by default") {
        let cfg = try ConfigParser.parse(args: ["photo.jpg"], isStdinTTY: true, isStdoutTTY: false)
        try assertFalse(cfg.autoFileOutput)
        try assertNil(cfg.output)
    }

    test("--json with file input auto-selects file output so stdout remains JSON") {
        let cfg = try ConfigParser.parse(args: ["photo.jpg", "--json"], isStdinTTY: true, isStdoutTTY: false)
        try assertTrue(cfg.autoFileOutput)
        try assertEqual(cfg.outputMode, .json)
    }

    test("stdin to terminal without output is rejected because no filename can be derived") {
        do {
            _ = try ConfigParser.parse(args: [], isStdinTTY: false, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if e.category != .user { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("stdin pipe with no positionals uses stdin as input") {
        let cfg = try ConfigParser.parse(args: [], isStdinTTY: false, isStdoutTTY: false)
        try assertEqual(cfg.mode, .process)
        try assertEqual(cfg.inputs.count, 1)
        try assertEqual(cfg.inputs[0], "-")
    }

    test("--format jpeg is rejected; jpg is the canonical spelling") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--format", "jpeg"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if e.category != .parser { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("png format reports alpha support and jpg reports opaque-only") {
        try assertTrue(OutputFormat.png.supportsTransparency)
        try assertFalse(OutputFormat.jpeg.supportsTransparency)
    }

    test("default auto output path uses _bgbgone suffix") {
        let path = OutputNaming.defaultOutputPath(inputPath: "/tmp/my.photo.jpg", format: .png)
        try assertEqual(path, "/tmp/my.photo_bgbgone.png")
    }

    test("stdin has no default auto output path") {
        try assertNil(OutputNaming.defaultOutputPath(inputPath: "-", format: .png))
    }

    test("--type covers every shared subject hint") {
        let cases: [(String, Algo)] = [
            ("auto", .auto),
            ("person", .person),
            ("product", .auto),
            ("car", .auto),
            ("animal", .auto),
            ("graphic", .auto),
            ("transportation", .auto),
            ("saliency", .saliency),
            ("vn-mask", .vnMask)
        ]
        for (raw, expected) in cases {
            let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--type", raw], isStdinTTY: true, isStdoutTTY: true)
            try assertEqual(cfg.algo, expected, " for --type \(raw)")
        }
    }

    test("CLIContract.subjectTypes is the SSOT — parser accepts every value, rejects everything else") {
        // The help text and docs are formatted from CLIContract.subjectTypes.
        // The parser is a switch in parseForegroundType. If the two diverge,
        // help text lies. This test ties them together.
        for raw in CLIContract.subjectTypes {
            let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--type", raw], isStdinTTY: true, isStdoutTTY: true)
            _ = cfg.algo  // any Algo result is acceptable; we only require no-throw
        }
    }

    test("--type bogus is rejected as a parser error") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--type", "alien"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if e.category == .parser {
                let m = e.message
                try assertTrue(m.contains("type"))
            } else {
                throw TestFailure("wrong error: \(e)")
            }
        }
    }

    test("--shadow-type none clears the drop shadow flag") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--shadow-type", "drop", "--shadow-type", "none"], isStdinTTY: true, isStdoutTTY: true)
        try assertFalse(cfg.dropShadow)
    }

    test("--shadow-type auto / drop / 3D / car enables the drop shadow") {
        for raw in ["auto", "drop", "3D", "car"] {
            let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--shadow-type", raw], isStdinTTY: true, isStdoutTTY: true)
            try assertTrue(cfg.dropShadow, " for --shadow-type \(raw)")
        }
    }

    test("--shadow-type bogus is rejected") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--shadow-type", "fake"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if e.category != .parser { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("--shadow-opacity 25 maps to 0.25") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--shadow-opacity", "25"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.shadowOpacity, 0.25)
    }

    test("--shadow-opacity auto leaves the default 0.50") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--shadow-opacity", "auto"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.shadowOpacity, 0.50)
    }

    test("--shadow-opacity out-of-range is rejected") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--shadow-opacity", "101"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if e.category != .parser { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("--semitransparency false hardens the matte") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--semitransparency", "false"], isStdinTTY: true, isStdoutTTY: true)
        try assertFalse(cfg.semitransparency)
    }

    test("--semitransparency true is the default and stays true") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--semitransparency", "true"], isStdinTTY: true, isStdoutTTY: true)
        try assertTrue(cfg.semitransparency)
    }

    test("--semitransparency maybe is rejected") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--semitransparency", "maybe"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if e.category != .parser { throw TestFailure("wrong error: \(e)") }
        }
    }

    // --scale and --position tests deleted - flags hard-removed in T54.
    // Use --filter "fg:scale=F" / --filter "fg:translate=X,Y" instead.
    // HTTP uses the same fg:scale / fg:translate filter grammar.

    test("--scale removed: rc=2 with unknown-option diagnostic") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--scale", "60%"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if e.category != .parser { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("--position removed: rc=2 with unknown-option diagnostic") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--position", "center"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if e.category != .parser { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("--roi with mixed % and px values parses dimensions correctly") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--roi", "10px 20% 80% 200px"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.roi, RectSpec(x1: .pixels(10), y1: .percent(0.20), x2: .percent(0.80), y2: .pixels(200)))
    }

    test("--roi malformed (only three values) is rejected") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--roi", "0 0 100"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if e.category != .parser { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("--crop-margin with one value applies to all four sides") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--crop-margin", "12px"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.cropMargins, EdgeInsetsSpec(top: .pixels(12), right: .pixels(12), bottom: .pixels(12), left: .pixels(12)))
    }

    test("--crop-margin with two values applies (vertical, horizontal)") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--crop-margin", "5% 10%"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.cropMargins, EdgeInsetsSpec(top: .percent(0.05), right: .percent(0.10), bottom: .percent(0.05), left: .percent(0.10)))
    }

    test("--crop-margin with three values is rejected (only 1, 2, or 4 allowed)") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--crop-margin", "1 2 3"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if e.category != .parser { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("--size preview / full / auto / 50MP set megapixel caps") {
        let cases: [(String, OutputFormat, Double)] = [
            ("preview", .jpeg, 0.25),
            ("full", .jpeg, 25.0),
            ("auto", .jpeg, 25.0),
            ("50MP", .jpeg, 50.0),
            ("full", .png, 10.0)
        ]
        for (raw, format, expected) in cases {
            let cfg = try ConfigParser.parse(
                args: ["in.jpg", "-o", "out", "--format", format.rawValue, "--size", raw],
                isStdinTTY: true,
                isStdoutTTY: true
            )
            try assertEqual(cfg.maxOutputMegapixels, expected, " for --size \(raw) format=\(format.rawValue)")
        }
    }

    test("--size bogus is rejected with a parser error") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--size", "4k"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if e.category != .parser { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("--quality out-of-range is rejected") {
        for raw in ["0", "101", "-1", "abc"] {
            do {
                _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--quality", raw], isStdinTTY: true, isStdoutTTY: true)
                throw TestFailure("expected throw for --quality \(raw)")
            } catch let e as BgBgOneError {
                if e.category != .parser { throw TestFailure("wrong error for \(raw): \(e)") }
            }
        }
    }

    test("--threshold is removed and rejected") {
        for raw in ["-0.1", "1.1", "abc"] {
            do {
                _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--threshold", raw], isStdinTTY: true, isStdoutTTY: true)
                throw TestFailure("expected throw for removed --threshold \(raw)")
            } catch let e as BgBgOneError {
                if e.category != .parser { throw TestFailure("wrong error for \(raw): \(e)") }
            }
        }
    }

    test("--feather is removed and rejected") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--feather", "-3"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if e.category != .parser { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("--crop-margin invalid syntax is rejected") {
        for raw in ["-1", "1%%", "wat"] {
            do {
                _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--crop-margin", raw], isStdinTTY: true, isStdoutTTY: true)
                throw TestFailure("expected throw for --crop-margin \(raw)")
            } catch let e as BgBgOneError {
                if e.category != .parser { throw TestFailure("wrong error for \(raw): \(e)") }
            }
        }
    }

    test("--bg color:rgb:r,g,b parses the rgb triple") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--bg", "color:rgb:0,128,255"], isStdinTTY: true, isStdoutTTY: true)
        if case .solidColor(let rgba) = cfg.background {
            try assertEqual(rgba.r, 0.0)
            try assertEqual(rgba.g, 128.0 / 255.0)
            try assertEqual(rgba.b, 1.0)
        } else {
            throw TestFailure("expected .solidColor, got \(String(describing: cfg.background))")
        }
    }

    test("a flag missing its required value reports a parser error") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if e.category == .parser {
                let m = e.message
                try assertTrue(m.contains("value"))
            } else {
                throw TestFailure("wrong error: \(e)")
            }
        }
    }
}
