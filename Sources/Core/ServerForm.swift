import Foundation

public struct ServerUploadedFile: Sendable, Equatable {
    public var filename: String
    public var contentType: String
    public var data: Data

    public init(filename: String, contentType: String, data: Data) {
        self.filename = filename
        self.contentType = contentType
        self.data = data
    }
}

public struct ServerForm: Sendable, Equatable {
    public var fields: [String: String]
    public var files: [String: ServerUploadedFile]

    public init(fields: [String: String] = [:], files: [String: ServerUploadedFile] = [:]) {
        self.fields = fields
        self.files = files
    }
}

public enum ServerFormParser {
    public static func parseURLEncoded(_ body: Data) -> ServerForm {
        let text = String(data: body, encoding: .utf8) ?? ""
        var fields: [String: String] = [:]
        for pair in text.split(separator: "&", omittingEmptySubsequences: false) {
            let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            let key = decodeFormComponent(parts.first.map(String.init) ?? "")
            if key.isEmpty { continue }
            let value = parts.count > 1 ? decodeFormComponent(String(parts[1])) : ""
            fields[key] = value
        }
        return ServerForm(fields: fields)
    }

    public static func parseJSON(_ body: Data) throws -> ServerForm {
        guard !body.isEmpty else {
            return ServerForm()
        }
        let value = try JSONSerialization.jsonObject(with: body)
        guard let object = value as? [String: Any] else {
            throw BgBgOneError.parser(
                ErrorCodes.parseHttpJsonNotObject,
                "JSON request body must be an object"
            )
        }
        var fields: [String: String] = [:]
        for (key, value) in object {
            switch value {
            case let string as String:
                fields[key] = string
            case let bool as Bool:
                fields[key] = bool ? "true" : "false"
            case let number as NSNumber:
                fields[key] = number.stringValue
            case is NSNull:
                continue
            default:
                throw BgBgOneError.parser(
                    ErrorCodes.parseHttpJsonInvalid,
                    "unsupported JSON value for field \(key)",
                    context: ["field": key]
                )
            }
        }
        return ServerForm(fields: fields)
    }

    public static func parseMultipart(_ body: Data, boundary: String) throws -> ServerForm {
        guard !boundary.isEmpty else {
            throw BgBgOneError.parser(
                ErrorCodes.parseHttpMultipartBoundaryMissing,
                "multipart boundary is required"
            )
        }

        let delimiter = Data("--\(boundary)".utf8)
        let headerSeparator = Data("\r\n\r\n".utf8)
        let chunks = body.split(separatorData: delimiter)
        var fields: [String: String] = [:]
        var files: [String: ServerUploadedFile] = [:]

        for rawChunk in chunks {
            var part = rawChunk
            part.trimCRLF()
            if part.isEmpty || part == Data("--".utf8) {
                continue
            }
            if part.ends(with: Data("--".utf8)) {
                part.removeLast(2)
                part.trimCRLF()
            }
            guard let headerEnd = part.range(of: headerSeparator) else {
                continue
            }

            let headerData = part[..<headerEnd.lowerBound]
            var content = Data(part[headerEnd.upperBound...])
            content.trimCRLF()

            guard let headerText = String(data: headerData, encoding: .utf8) else {
                continue
            }
            let headers = parsePartHeaders(headerText)
            guard let disposition = headers["content-disposition"],
                  let name = dispositionParameter("name", in: disposition) else {
                continue
            }

            if let filename = dispositionParameter("filename", in: disposition) {
                let contentType = headers["content-type"] ?? "application/octet-stream"
                files[name] = ServerUploadedFile(filename: filename, contentType: contentType, data: content)
            } else {
                fields[name] = String(data: content, encoding: .utf8) ?? ""
            }
        }

        return ServerForm(fields: fields, files: files)
    }

    private static func parsePartHeaders(_ text: String) -> [String: String] {
        var headers: [String: String] = [:]
        for line in text.components(separatedBy: "\r\n") {
            let parts = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else { continue }
            headers[String(parts[0]).trimmingCharacters(in: .whitespaces).lowercased()] =
                String(parts[1]).trimmingCharacters(in: .whitespaces)
        }
        return headers
    }

    private static func dispositionParameter(_ key: String, in disposition: String) -> String? {
        for component in disposition.split(separator: ";") {
            let parts = component.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else { continue }
            let paramKey = parts[0].trimmingCharacters(in: .whitespaces)
            guard paramKey == key else { continue }
            return String(parts[1]).trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }
        return nil
    }

    private static func decodeFormComponent(_ value: String) -> String {
        value.replacingOccurrences(of: "+", with: " ").removingPercentEncoding ?? value
    }
}

private extension Data {
    func split(separatorData: Data) -> [Data] {
        guard !separatorData.isEmpty else { return [self] }
        var pieces: [Data] = []
        var searchStart = startIndex
        while searchStart < endIndex, let range = self[searchStart...].range(of: separatorData) {
            pieces.append(Data(self[searchStart..<range.lowerBound]))
            searchStart = range.upperBound
        }
        pieces.append(Data(self[searchStart..<endIndex]))
        return pieces
    }

    func ends(with suffix: Data) -> Bool {
        count >= suffix.count && self[(endIndex - suffix.count)..<endIndex] == suffix
    }

    mutating func trimCRLF() {
        while first == 13 || first == 10 {
            removeFirst()
        }
        while last == 13 || last == 10 {
            removeLast()
        }
    }
}
