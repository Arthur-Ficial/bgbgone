import Foundation
import ArgumentParser

/// Static entry point preserved across the swift-argument-parser migration so
/// every test and call site stays source-compatible. The implementation
/// delegates to `BgBgOneCommand` (swift-argument-parser) and then runs the
/// cross-cutting resolution that the parser itself cannot do (TTY-dependent
/// autoFileOutput, env-var defaults, output-format inference, mutex checks).
public enum ConfigParser {

    public static func parse(
        args: [String],
        isStdinTTY: Bool,
        isStdoutTTY: Bool,
        stdoutPath: String? = nil,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> Config {
        let cmd: BgBgOneCommand
        do {
            cmd = try BgBgOneCommand.parseAsRoot(args) as! BgBgOneCommand
        } catch {
            throw ConfigBuilder.translate(parserError: error, args: args)
        }
        return try ConfigBuilder.build(
            cmd: cmd,
            isStdinTTY: isStdinTTY,
            isStdoutTTY: isStdoutTTY,
            stdoutPath: stdoutPath,
            environment: environment
        )
    }
}
