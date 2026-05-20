import Foundation
import BgBgOneCore

func runColourParserTests() {
    test("#fff -> white") {
        let c = try ColourParser.parse("#fff")
        try assertEqual(c.r, 1.0)
        try assertEqual(c.g, 1.0)
        try assertEqual(c.b, 1.0)
        try assertEqual(c.a, 1.0)
    }

    test("#000 -> black") {
        let c = try ColourParser.parse("#000")
        try assertEqual(c.r, 0.0)
        try assertEqual(c.g, 0.0)
        try assertEqual(c.b, 0.0)
    }

    test("#ff0000 -> red") {
        let c = try ColourParser.parse("#ff0000")
        try assertEqual(c.r, 1.0)
        try assertEqual(c.g, 0.0)
        try assertEqual(c.b, 0.0)
    }

    test("#00ff0080 -> half-transparent green") {
        let c = try ColourParser.parse("#00ff0080")
        try assertEqual(c.r, 0.0)
        try assertEqual(c.g, 1.0)
        try assertEqual(c.b, 0.0)
        // 0x80 / 0xff ≈ 0.5019607
        try assertTrue(abs(c.a - 0x80 / 255.0) < 0.001)
    }

    test("named white") {
        let c = try ColourParser.parse("white")
        try assertEqual(c.r, 1.0)
        try assertEqual(c.a, 1.0)
    }

    test("named black") {
        let c = try ColourParser.parse("black")
        try assertEqual(c.r, 0.0)
    }

    test("named red") {
        let c = try ColourParser.parse("red")
        try assertEqual(c.r, 1.0)
        try assertEqual(c.g, 0.0)
        try assertEqual(c.b, 0.0)
    }

    test("rgb:255,0,0 -> red") {
        let c = try ColourParser.parse("rgb:255,0,0")
        try assertEqual(c.r, 1.0)
        try assertEqual(c.g, 0.0)
        try assertEqual(c.b, 0.0)
    }

    test("rgb:128,128,128 -> mid grey") {
        let c = try ColourParser.parse("rgb:128,128,128")
        try assertTrue(abs(c.r - 128.0/255.0) < 0.001)
        try assertTrue(abs(c.g - 128.0/255.0) < 0.001)
        try assertTrue(abs(c.b - 128.0/255.0) < 0.001)
    }

    test("rgba:255,0,0,128 -> half-transparent red") {
        let c = try ColourParser.parse("rgba:255,0,0,128")
        try assertEqual(c.r, 1.0)
        try assertTrue(abs(c.a - 128.0/255.0) < 0.001)
    }

    test("bad hex throws") {
        do {
            _ = try ColourParser.parse("#xyz")
            throw TestFailure("expected throw")
        } catch is BgBgOneError {
            // expected
        }
    }

    test("unknown named throws") {
        do {
            _ = try ColourParser.parse("unobtaniumblue")
            throw TestFailure("expected throw")
        } catch is BgBgOneError {
            // expected
        }
    }

    test("rgb out of range throws") {
        do {
            _ = try ColourParser.parse("rgb:300,0,0")
            throw TestFailure("expected throw")
        } catch is BgBgOneError {
            // expected
        }
    }
}
