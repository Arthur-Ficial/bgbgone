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

    test("--to webp / heic / avif / tiff") {
        try assertEqual(
            try ConfigParser.parse(args: ["in.jpg", "-o", "x", "--to", "webp"], isStdinTTY: true, isStdoutTTY: true).outputFormat,
            .webp
        )
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

    test("--bg gen:<prompt> rejected with explanatory error (removed in v0.1.2)") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--bg", "gen:sunset over mountains"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw — gen: should be rejected")
        } catch let e as BgBgOneError {
            if case .parser(let m) = e {
                try assertTrue(m.contains("gen:") || m.contains("removed"))
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

    test("--algo auto / vn-remove / vn-mask / person / sky / saliency") {
        for raw in ["auto", "vn-remove", "vn-mask", "person", "sky", "saliency"] {
            let cfg = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--algo", raw], isStdinTTY: true, isStdoutTTY: true)
            try assertEqual(cfg.algo.rawValue, raw)
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

    test("--style is no longer a known flag (removed with gen:)") {
        do {
            _ = try ConfigParser.parse(args: ["in.jpg", "-o", "out", "--style", "sketch"], isStdinTTY: true, isStdoutTTY: true)
            throw TestFailure("expected throw — --style should be unknown")
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

    test("stdout TTY with no -o and process mode is rejected") {
        // bgbgone in.jpg with stdout TTY and no -o → user error (refuse binary to terminal)
        do {
            _ = try ConfigParser.parse(args: ["in.jpg"], isStdinTTY: true, isStdoutTTY: true)
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
}
