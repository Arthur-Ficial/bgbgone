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
            if case .userError(let message) = e {
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
        let cfg = try ConfigParser.parse(args: ["--to", "jpg", "--", "-portrait.png"], isStdinTTY: true, isStdoutTTY: false)
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

    test("explicit --to wins over output extension") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out.jpg", "--to", "png"], isStdinTTY: true, isStdoutTTY: true)
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
            if case .userError(let message) = e {
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
            if case .userError(let message) = e {
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
            if case .userError(let message) = e {
                try assertTrue(message.contains("stdin") && message.contains("-o"))
            } else {
                throw TestFailure("wrong error: \(e)")
            }
        }
    }

    test("--to png sets format") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--to", "png"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.outputFormat, .png)
    }

    test("--to jpg") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--to", "jpg"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.outputFormat, .jpeg)
    }

    test("--to heic / avif / tiff") {
        try assertEqual(
            try ConfigParser.parse(args: ["in.jpg", "-o", "x", "--to", "heic"], isStdinTTY: true, isStdoutTTY: true).outputFormat,
            .heic
        )
        try assertEqual(
            try ConfigParser.parse(args: ["in.jpg", "-o", "x", "--to", "avif"], isStdinTTY: true, isStdoutTTY: true).outputFormat,
            .avif
        )
        try assertEqual(
            try ConfigParser.parse(args: ["in.jpg", "-o", "x", "--to", "tiff"], isStdinTTY: true, isStdoutTTY: true).outputFormat,
            .tiff
        )
    }

    test("--to zip is accepted as a split color-and-alpha package") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out.zip", "--to", "zip"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.outputFormat, .zip)
    }

    test("--format is the CLI spelling for the same output format contract") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out.zip", "--format", "zip"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.outputFormat, .zip)
    }

    test("--to webp is rejected (not supported by ImageIO on this SDK)") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "x", "--to", "webp"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw — webp is not supported")
        } catch let e as BgBgOneError {
            if case .parser = e { } else { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("--to bogus throws parser error") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--to", "bmp"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if case .parser = e { } else { throw TestFailure("wrong error: \(e)") }
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

    test("--bg-color parses the shared solid colour field") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--bg-color", "fff"], isStdinTTY: true, isStdoutTTY: true)
        if case .solidColor(let rgba) = cfg.background {
            try assertEqual(rgba.r, 1.0)
            try assertEqual(rgba.g, 1.0)
            try assertEqual(rgba.b, 1.0)
        } else {
            throw TestFailure("expected .solidColor, got \(String(describing: cfg.background))")
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

    test("--bg-image parses the shared background image field") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--bg-image", "./bg.jpg"], isStdinTTY: true, isStdoutTTY: true)
        if case .image(let path) = cfg.background {
            try assertEqual(path, "./bg.jpg")
        } else {
            throw TestFailure("expected .image, got \(String(describing: cfg.background))")
        }
    }

    test("--bg with unknown scheme is rejected as a parser error") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--bg", "magic:sunset"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if case .parser(let m) = e {
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

    test("--algo auto / vn-mask / person / saliency parses") {
        for raw in ["auto", "vn-mask", "person", "saliency"] {
            let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--algo", raw], isStdinTTY: true, isStdoutTTY: true)
            try assertEqual(cfg.algo.rawValue, raw)
        }
    }

    test("--type maps shared foreground type hints to local algorithms") {
        let person = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--type", "person"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(person.algo, .person)

        let product = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--type", "product"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(product.algo, .auto)
    }

    test("--algo vn-remove and --algo sky are rejected (not in public SDK)") {
        for raw in ["vn-remove", "sky"] {
            do {
                _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--algo", raw], isStdinTTY: true, isStdoutTTY: true)
                throw TestFailure("expected throw for --algo \(raw)")
            } catch let e as BgBgOneError {
                if case .parser = e { } else { throw TestFailure("wrong error for \(raw): \(e)") }
            }
        }
    }

    test("--algo bogus throws") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--algo", "magic"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if case .parser = e { } else { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("--mask-only sets maskOnly true") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--mask-only"], isStdinTTY: true, isStdoutTTY: true)
        try assertTrue(cfg.maskOnly)
    }

    test("--channels alpha maps to the same mask-only output as the server") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--channels", "alpha"], isStdinTTY: true, isStdoutTTY: true)
        try assertTrue(cfg.maskOnly)
        try assertEqual(cfg.outputFormat, .png)
    }

    test("--channels rgba keeps finalized image output") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--channels", "rgba"], isStdinTTY: true, isStdoutTTY: true)
        try assertFalse(cfg.maskOnly)
    }

    test("--feather 4 parses") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--feather", "4"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.feather, 4.0)
    }

    test("--threshold 0.5") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--threshold", "0.5"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.threshold, 0.5)
    }

    test("--padding percent: 10% -> 0.10 percent mode") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--padding", "10%"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.padding, 0.10)
        try assertTrue(cfg.paddingIsPercent)
    }

    test("--padding pixels: 24 -> 24px mode") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--padding", "24"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.padding, 24.0)
        try assertFalse(cfg.paddingIsPercent)
    }

    test("--crop sets crop true") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--crop"], isStdinTTY: true, isStdoutTTY: true)
        try assertTrue(cfg.cropToSubject)
    }

    test("--shadow sets shadow true") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--shadow"], isStdinTTY: true, isStdoutTTY: true)
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
                "--scale", "50%",
                "--position", "25% 75%",
                "--semitransparency", "false",
                "--shadow-type", "drop",
                "--shadow-opacity", "25"
            ],
            isStdinTTY: true,
            isStdoutTTY: true
        )
        try assertEqual(cfg.maxOutputMegapixels, 25.0)
        try assertEqual(cfg.roi, ServerRectSpec(x1: .percent(0.10), y1: .percent(0.20), x2: .percent(0.90), y2: .percent(0.80)))
        try assertEqual(cfg.cropMargins, ServerEdgeInsets(top: .pixels(10), right: .pixels(20), bottom: .pixels(30), left: .pixels(40)))
        try assertEqual(cfg.scalePercent, 0.50)
        try assertEqual(cfg.position, ServerPosition(x: 0.25, y: 0.75))
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
            if case .userError(let message) = e {
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
            if case .userError(let message) = e {
                try assertTrue(message.contains("--multi") && message.contains("stdin"))
            } else {
                throw TestFailure("wrong error: \(e)")
            }
        }
    }

    test("--multi and --mask-only are rejected instead of silently ignoring one mode") {
        do {
            _ = try ConfigParser.parse(args: ["team.jpg", "--multi", "--mask-only", "--out-dir", "./people"], isStdinTTY: true, isStdoutTTY: false)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if case .userError(let message) = e {
                try assertTrue(message.contains("--multi") && message.contains("--mask-only"))
            } else {
                throw TestFailure("wrong error: \(e)")
            }
        }
    }

    test("--json sets outputMode .json") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--json"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.outputMode, .json)
    }

    test("--json and --ndjson are rejected together") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out.png", "--json", "--ndjson"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if case .userError(let message) = e {
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
            if case .userError(let message) = e {
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
            if case .parser = e { } else { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("unknown flag throws parser error") {
        do {
            _ = try ConfigParser.parse(args: ["--made-up-flag"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if case .parser = e { } else { throw TestFailure("wrong error: \(e)") }
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
            if case .userError = e { } else { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("stdin pipe with no positionals uses stdin as input") {
        let cfg = try ConfigParser.parse(args: [], isStdinTTY: false, isStdoutTTY: false)
        try assertEqual(cfg.mode, .process)
        try assertEqual(cfg.inputs.count, 1)
        try assertEqual(cfg.inputs[0], "-")
    }

    test("--to jpeg is accepted as a user-friendly alias for jpg") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--to", "jpeg"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.outputFormat, .jpeg)
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

    test("--type bogus is rejected as a parser error") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--type", "alien"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if case .parser(let m) = e {
                try assertTrue(m.contains("type"))
            } else {
                throw TestFailure("wrong error: \(e)")
            }
        }
    }

    test("--shadow-type none clears the drop shadow flag") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--shadow", "--shadow-type", "none"], isStdinTTY: true, isStdoutTTY: true)
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
            if case .parser = e { } else { throw TestFailure("wrong error: \(e)") }
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
            if case .parser = e { } else { throw TestFailure("wrong error: \(e)") }
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
            if case .parser = e { } else { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("--scale and --position interact: --scale alone implies --position center") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--scale", "60%"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.scalePercent, 0.60)
        try assertEqual(cfg.position, ServerPosition.center)
    }

    test("--scale original is a no-op (treated as nil)") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--scale", "original"], isStdinTTY: true, isStdoutTTY: true)
        try assertNil(cfg.scalePercent)
        try assertNil(cfg.position)
    }

    test("--scale below 10% is rejected") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--scale", "5%"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if case .parser = e { } else { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("--position original keeps position nil when no scale is set") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--position", "original"], isStdinTTY: true, isStdoutTTY: true)
        try assertNil(cfg.position)
    }

    test("--position original combined with --scale still centres the scaled subject") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--scale", "50%", "--position", "original"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.position, ServerPosition.center, " — scaled subjects must land somewhere on the canvas")
    }

    test("--position center sets a centered placement") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--position", "center"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.position, ServerPosition.center)
    }

    test("--position with single percent applies to both axes") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--position", "75%"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.position, ServerPosition(x: 0.75, y: 0.75))
    }

    test("--position with two percents maps to (x, y)") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--position", "10% 90%"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.position, ServerPosition(x: 0.10, y: 0.90))
    }

    test("--roi with mixed % and px values parses dimensions correctly") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--roi", "10px 20% 80% 200px"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.roi, ServerRectSpec(x1: .pixels(10), y1: .percent(0.20), x2: .percent(0.80), y2: .pixels(200)))
    }

    test("--roi malformed (only three values) is rejected") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--roi", "0 0 100"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if case .parser = e { } else { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("--crop-margin with one value applies to all four sides") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--crop-margin", "12px"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.cropMargins, ServerEdgeInsets(top: .pixels(12), right: .pixels(12), bottom: .pixels(12), left: .pixels(12)))
    }

    test("--crop-margin with two values applies (vertical, horizontal)") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--crop-margin", "5% 10%"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.cropMargins, ServerEdgeInsets(top: .percent(0.05), right: .percent(0.10), bottom: .percent(0.05), left: .percent(0.10)))
    }

    test("--crop-margin with three values is rejected (only 1, 2, or 4 allowed)") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--crop-margin", "1 2 3"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if case .parser = e { } else { throw TestFailure("wrong error: \(e)") }
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
            if case .parser = e { } else { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("--quality out-of-range is rejected") {
        for raw in ["0", "101", "-1", "abc"] {
            do {
                _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--quality", raw], isStdinTTY: true, isStdoutTTY: true)
                throw TestFailure("expected throw for --quality \(raw)")
            } catch let e as BgBgOneError {
                if case .parser = e { } else { throw TestFailure("wrong error for \(raw): \(e)") }
            }
        }
    }

    test("--threshold out-of-range is rejected") {
        for raw in ["-0.1", "1.1", "abc"] {
            do {
                _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--threshold", raw], isStdinTTY: true, isStdoutTTY: true)
                throw TestFailure("expected throw for --threshold \(raw)")
            } catch let e as BgBgOneError {
                if case .parser = e { } else { throw TestFailure("wrong error for \(raw): \(e)") }
            }
        }
    }

    test("--feather negative is rejected") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--feather", "-3"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw")
        } catch let e as BgBgOneError {
            if case .parser = e { } else { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("--padding invalid syntax is rejected") {
        for raw in ["-1", "1%%", "wat"] {
            do {
                _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--padding", raw], isStdinTTY: true, isStdoutTTY: true)
                throw TestFailure("expected throw for --padding \(raw)")
            } catch let e as BgBgOneError {
                if case .parser = e { } else { throw TestFailure("wrong error for \(raw): \(e)") }
            }
        }
    }

    test("--bg-color rgb:r,g,b parses the rgb triple") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--bg-color", "rgb:0,128,255"], isStdinTTY: true, isStdoutTTY: true)
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
            if case .parser(let m) = e {
                try assertTrue(m.contains("value"))
            } else {
                throw TestFailure("wrong error: \(e)")
            }
        }
    }
}
