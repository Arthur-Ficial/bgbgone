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
//
// Single-input → run on the current thread (preserve exit code & stdout-image
// behaviour for piping and unit tests).
// Batch (N > 1) → run in parallel with DispatchQueue.concurrentPerform so the
// Apple-Silicon CPU + Neural Engine pipeline is actually used. Per-iteration
// writes go to a unique slot (no shared mutation), and we emit stderr / stdout
// in original input order at the end so behaviour is deterministic.
if cfg.inputs.count == 1 {
    let input = cfg.inputs[0]
    do {
        let results = try BgBgOne.runMany(cfg)
        for result in results {
            if cfg.outputMode == .json || cfg.outputMode == .ndjson {
                print(result.toJSON())
            } else if !cfg.quiet && result.output != "-" {
                FileHandle.standardError.write(Data("bgbgone: \(result.input) -> \(result.output) [\(result.algo)] \(result.width)x\(result.height)\n".utf8))
            }
        }
        exit(0)
    } catch let e as BgBgOneError {
        FileHandle.standardError.write(Data("bgbgone: \(input): \(e.message)\n".utf8))
        exit(e.exitCode)
    } catch {
        FileHandle.standardError.write(Data("bgbgone: \(input): \(error.localizedDescription)\n".utf8))
        exit(3)
    }
} else {
    let count = cfg.inputs.count
    let buffer = BatchResultsBuffer(count: count)
    let sharedCfg = cfg

    DispatchQueue.concurrentPerform(iterations: count) { i in
        var perInput = sharedCfg
        perInput.inputs = [sharedCfg.inputs[i]]
        do {
            let r = try BgBgOne.runMany(perInput)
            buffer.setSuccess(i, r)
        } catch let e as BgBgOneError {
            buffer.setFailure(i, e)
        } catch {
            buffer.setFailure(i, BgBgOneError.frameworkError(error.localizedDescription))
        }
    }

    var hadFailure = false
    for i in 0..<count {
        let input = sharedCfg.inputs[i]
        guard let r = buffer.get(i) else { continue }
        switch r {
        case .success(let results):
            for result in results {
                if cfg.outputMode == .json || cfg.outputMode == .ndjson {
                    print(result.toJSON())
                } else if !cfg.quiet && result.output != "-" {
                    FileHandle.standardError.write(Data("bgbgone: \(result.input) -> \(result.output) [\(result.algo)] \(result.width)x\(result.height)\n".utf8))
                }
            }
        case .failure(let e):
            FileHandle.standardError.write(Data("bgbgone: \(input): \(e.message)\n".utf8))
            hadFailure = true
        }
    }
    exit(hadFailure ? 1 : 0)
}

/// Indexed write buffer for parallel batch results. concurrentPerform writes
/// to disjoint indices (one per input), so per-slot writes are race-free; the
/// `@unchecked Sendable` annotation is the explicit assertion that the
/// caller upholds that invariant.
private final class BatchResultsBuffer: @unchecked Sendable {
    private let ptr: UnsafeMutablePointer<Result<[RunResult], BgBgOneError>?>
    private let count: Int
    init(count: Int) {
        self.count = count
        self.ptr = UnsafeMutablePointer.allocate(capacity: count)
        self.ptr.initialize(repeating: nil, count: count)
    }
    deinit {
        ptr.deinitialize(count: count)
        ptr.deallocate()
    }
    func setSuccess(_ i: Int, _ v: [RunResult]) {
        (ptr + i).pointee = .success(v)
    }
    func setFailure(_ i: Int, _ e: BgBgOneError) {
        (ptr + i).pointee = .failure(e)
    }
    func get(_ i: Int) -> Result<[RunResult], BgBgOneError>? {
        (ptr + i).pointee
    }
}

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
