// NetworkGuard.swift — Hard-blocks any HTTP/HTTPS/WS/WSS request inside bgbgone.
// bgbgone is "100% on-device" by promise; this is the runtime enforcement.

import Foundation
import BgBgOneCore

enum NetworkGuard {
    static func install() {
        URLProtocol.registerClass(DenyNetworkURLProtocol.self)
    }
}

final class DenyNetworkURLProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool {
        NetworkPolicy.isBlockedNetworkScheme(request.url?.scheme)
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let urlText = request.url?.absoluteString ?? "<unknown>"
        FileHandle.standardError.write(Data("bgbgone: network call blocked: \(urlText)\n".utf8))
        Darwin.exit(3)
    }

    override func stopLoading() {}
}
