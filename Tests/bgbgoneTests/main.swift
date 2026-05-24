// bgbgone-tests — pure Swift test runner, no XCTest/Testing framework.
// Run: swift run bgbgone-tests

import Foundation

// MARK: - Minimal harness

nonisolated(unsafe) var _passed = 0
nonisolated(unsafe) var _failed = 0

func test(_ name: String, _ block: () throws -> Void) {
    do {
        try block()
        print("  \u{2705} \(name)")
        _passed += 1
    } catch {
        print("  \u{274C} \(name): \(error)")
        _failed += 1
    }
}

func assertEqual<T: Equatable>(_ a: T, _ b: T, _ msg: String = "") throws {
    guard a == b else { throw TestFailure("\(a) != \(b)\(msg.isEmpty ? "" : " — \(msg)")") }
}
func assertNil<T>(_ v: T?, _ msg: String = "") throws {
    guard v == nil else { throw TestFailure("Expected nil, got \(v!)\(msg.isEmpty ? "" : " — \(msg)")") }
}
func assertNotNil<T>(_ v: T?, _ msg: String = "") throws {
    guard v != nil else { throw TestFailure("Expected non-nil\(msg.isEmpty ? "" : " — \(msg)")") }
}
func assertNotNilAndUnwrap<T>(_ v: T?, _ msg: String = "") throws -> T {
    guard let v else { throw TestFailure("Expected non-nil\(msg.isEmpty ? "" : " — \(msg)")") }
    return v
}
func assertTrue(_ v: Bool, _ msg: String = "") throws {
    guard v else { throw TestFailure("Expected true\(msg.isEmpty ? "" : " — \(msg)")") }
}
func assertFalse(_ v: Bool, _ msg: String = "") throws {
    guard !v else { throw TestFailure("Expected false\(msg.isEmpty ? "" : " — \(msg)")") }
}
func assertThrows(_ msg: String = "", _ block: () throws -> Void) throws {
    do {
        try block()
        throw TestFailure("Expected throw\(msg.isEmpty ? "" : " — \(msg)")")
    } catch is TestFailure {
        throw TestFailure("Expected throw\(msg.isEmpty ? "" : " — \(msg)")")
    } catch {
        // expected
    }
}

struct TestFailure: Error, CustomStringConvertible {
    let description: String
    init(_ msg: String) { description = msg }
}

func suite(_ name: String, _ block: () -> Void) {
    print("\n\(name)")
    block()
}

// MARK: - Suites (one entry per *Tests.swift file)

suite("ColourParserTests") { runColourParserTests() }
suite("ConfigParserTests") { runConfigParserTests() }
suite("JSONEscaperTests") { runJSONEscaperTests() }
suite("NetworkGuardTests") { runNetworkGuardTests() }
suite("NamingTests") { runNamingTests() }
suite("ServerConfigTests") { runServerConfigTests() }
suite("ServerRequestTests") { runServerRequestTests() }
suite("ServerParsingTests") { runServerParsingTests() }
suite("ServerSecurityTests") { runServerSecurityTests() }

// MARK: - Summary

print("\n" + String(repeating: "\u{2500}", count: 32))
if _failed == 0 {
    print("\u{2705} All \(_passed) tests passed")
} else {
    print("\u{274C} \(_failed) failed, \(_passed) passed")
    exit(1)
}
