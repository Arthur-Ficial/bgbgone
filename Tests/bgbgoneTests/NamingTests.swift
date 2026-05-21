import Foundation
import BgBgOneCore

func runNamingTests() {
    test("default template {base}-{n}.{ext}") {
        let s = InstanceNaming.expand(template: "{base}-{n}.{ext}", base: "einstein", n: 1, ext: "png")
        try assertEqual(s, "einstein-1.png")
    }

    test("zero-padded {n:03}") {
        let s = InstanceNaming.expand(template: "{base}_{n:03}.{ext}", base: "crew", n: 5, ext: "jpg")
        try assertEqual(s, "crew_005.jpg")
    }

    test("base with dots is preserved verbatim") {
        let s = InstanceNaming.expand(template: "{base}-{n}.{ext}", base: "my.photo", n: 2, ext: "png")
        try assertEqual(s, "my.photo-2.png")
    }

    test("template without any tokens passes through (legal but unusual)") {
        let s = InstanceNaming.expand(template: "literal.png", base: "x", n: 1, ext: "png")
        try assertEqual(s, "literal.png")
    }

    test("extension-only template") {
        let s = InstanceNaming.expand(template: "out{n}.{ext}", base: "ignored", n: 42, ext: "jpg")
        try assertEqual(s, "out42.jpg")
    }

    test("batch output path keeps input stem and uses selected format extension") {
        let path = OutputNaming.batchOutputPath(inputPath: "/tmp/my.photo.png", outDir: "/out", format: .jpeg)
        try assertEqual(path, "/out/my.photo.jpg")
    }

    test("batch output path is nil for stdin because stdin has no stable stem") {
        try assertNil(OutputNaming.batchOutputPath(inputPath: "-", outDir: "/out", format: .png))
    }
}
