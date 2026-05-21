import Foundation
import Darwin
import BgBgOneCore

NetworkGuard.install()

let args = Array(CommandLine.arguments.dropFirst())
let isStdinTTY = isatty(fileno(stdin)) != 0
let isStdoutTTY = isatty(fileno(stdout)) != 0

let cfg: Config
do {
    cfg = try ConfigParser.parse(
        args: args,
        isStdinTTY: isStdinTTY,
        isStdoutTTY: isStdoutTTY,
        stdoutPath: stdoutFilePath()
    )
} catch let e as BgBgOneError {
    FileHandle.standardError.write(Data("bgbgone: \(e.message)\n".utf8))
    exit(e.exitCode)
} catch {
    FileHandle.standardError.write(Data("bgbgone: \(error.localizedDescription)\n".utf8))
    exit(2)
}

switch cfg.mode {
case .helpRequested:
    CLI.printHelp()
    exit(0)
case .versionRequested:
    CLI.printVersion()
    exit(0)
case .capabilityCheckRequested:
    CLI.printCheck()
    exit(0)
case .serverRequested:
    do {
        try BgBgOneHTTPServer(config: cfg.server, quiet: cfg.quiet).start()
    } catch let e as BgBgOneError {
        FileHandle.standardError.write(Data("bgbgone: \(e.message)\n".utf8))
        exit(e.exitCode)
    } catch {
        FileHandle.standardError.write(Data("bgbgone: \(error.localizedDescription)\n".utf8))
        exit(3)
    }
case .process:
    break
}

// Fan out across inputs (batch mode). Each iteration uses a single-input Config.
var hadFailure = false
for input in cfg.inputs {
    var perInput = cfg
    perInput.inputs = [input]
    do {
        let results = try MainActor.assumeIsolated {
            try BgBgOne.runMany(perInput)
        }
        for result in results {
            if cfg.outputMode == .json || cfg.outputMode == .ndjson {
                print(result.toJSON())
            } else if !cfg.quiet && result.output != "-" {
                FileHandle.standardError.write(Data("bgbgone: \(result.input) -> \(result.output) [\(result.algo)] \(result.width)x\(result.height)\n".utf8))
            }
        }
    } catch let e as BgBgOneError {
        FileHandle.standardError.write(Data("bgbgone: \(input): \(e.message)\n".utf8))
        if cfg.inputs.count == 1 {
            exit(e.exitCode)
        }
        hadFailure = true
    } catch {
        FileHandle.standardError.write(Data("bgbgone: \(input): \(error.localizedDescription)\n".utf8))
        if cfg.inputs.count == 1 {
            exit(3)
        }
        hadFailure = true
    }
}
exit(hadFailure ? 1 : 0)

private func stdoutFilePath() -> String? {
    guard isatty(fileno(stdout)) == 0 else { return nil }

    var path = [CChar](repeating: 0, count: Int(MAXPATHLEN))
    let rc = path.withUnsafeMutableBufferPointer { buffer in
        guard let base = buffer.baseAddress else { return Int32(-1) }
        return fcntl(fileno(stdout), F_GETPATH, UnsafeMutableRawPointer(base))
    }
    guard rc != -1 else { return nil }

    let resolved = path.withUnsafeBufferPointer { buffer in
        String(cString: buffer.baseAddress!)
    }
    return resolved.isEmpty ? nil : resolved
}
