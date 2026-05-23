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

/// Layer prefix for a stage. `all` is the default when no prefix is given.
public enum FilterLayer: String, Sendable, Equatable, CaseIterable {
    case fg
    case bg
    case all
    case mask
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
}
