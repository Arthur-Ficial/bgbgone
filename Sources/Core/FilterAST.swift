import Foundation

/// One filter invocation: name + ordered positional args + keyed args.
public struct FilterCall: Sendable, Equatable {
    public let name: String
    public let args: [FilterArg]

    public init(name: String, args: [FilterArg] = []) {
        self.name = name
        self.args = args
    }
}

/// An argument to a filter. Either a bare value (`bg:blur=15`) or a keyed
/// pair (`fg:outline=color=#fff:width=3`).
public enum FilterArg: Sendable, Equatable {
    case value(String)
    case keyed(key: String, value: String)
}

/// Layer prefix for a stage.
///
/// `all` means "apply independently to foreground and background before
/// compositing". Filters that operate on the already-flattened image must use
/// `composite`; keeping those surfaces distinct avoids ffmpeg-style ambiguity
/// around whether a filter sees layers or final pixels.
public enum FilterLayer: String, Sendable, Equatable, CaseIterable {
    case fg
    case bg
    case all
    case mask
    case composite
}

/// A stage = one layer + one or more comma-separated filters. Order matters.
public struct FilterStage: Sendable, Equatable {
    public let layer: FilterLayer
    public let calls: [FilterCall]

    public init(layer: FilterLayer = .all, calls: [FilterCall]) {
        self.layer = layer
        self.calls = calls
    }
}

/// One `--filter` chain = zero or more semicolon-separated stages.
/// Empty chain == no filter (downstream is byte-identical to no `--filter`).
public struct FilterChain: Sendable, Equatable {
    public let stages: [FilterStage]
    public init(stages: [FilterStage]) { self.stages = stages }

    public var isEmpty: Bool { stages.isEmpty }

    public var normalizedString: String {
        stages.map { stage in
            let calls = stage.calls.map { call in
                guard !call.args.isEmpty else { return call.name.lowercased() }
                let args = call.args.map { arg in
                    switch arg {
                    case .value(let value):
                        return value
                    case .keyed(let key, let value):
                        return "\(key)=\(value)"
                    }
                }.joined(separator: ":")
                return "\(call.name.lowercased())=\(args)"
            }.joined(separator: ",")
            return "\(stage.layer.rawValue):\(calls)"
        }.joined(separator: ";")
    }
}
