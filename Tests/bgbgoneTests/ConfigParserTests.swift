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

    test("--bg image:./bg.jpg parses image bg") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--bg", "image:./bg.jpg"], isStdinTTY: true, isStdoutTTY: true)
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

    test("--multi sets multiInstance true") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--multi"], isStdinTTY: true, isStdoutTTY: true)
        try assertTrue(cfg.multiInstance)
    }

    test("--json sets outputMode .json") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--json"], isStdinTTY: true, isStdoutTTY: true)
        try assertEqual(cfg.outputMode, .json)
    }

    test("--quiet sets quiet true") {
        let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--quiet"], isStdinTTY: true, isStdoutTTY: true)
        try assertTrue(cfg.quiet)
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
}
