import Foundation

public enum ServerResponseKind: Sendable, Equatable {
    case image
    case json
}

public enum ServerInputSource: Sendable, Equatable {
    case uploaded(Data, filename: String)
}

public struct ServerRemovalRequest: Sendable, Equatable {
    public var input: ServerInputSource
    public var config: Config
    public var responseKind: ServerResponseKind

    public static func parse(form: ServerForm, inputPath: String, backgroundImagePath: String?) throws -> ServerRemovalRequest {
        if form.fields["image_url"] != nil {
            throw BgBgOneError.userError("image_url is not supported by the local server; upload image_file or image_file_b64")
        }
        if form.fields["bg_image_url"] != nil {
            throw BgBgOneError.userError("bg_image_url is not supported by the local server; upload bg_image_file or bg_image_file_b64")
        }

        let input = try parseInput(form)
        var cfg = Config(mode: .process)
        cfg.inputs = [inputPath]
        cfg.output = nil
        cfg.outputDir = nil
        cfg.autoFileOutput = false
        cfg.quiet = true

        let rawFormat = normalized(form.fields["format"] ?? "png")
        let responseKind: ServerResponseKind
        if rawFormat == "json" {
            responseKind = .json
            cfg.outputFormat = .png
        } else {
            responseKind = .image
            guard let format = OutputFormat.parse(rawFormat) else {
                throw BgBgOneError.parser("unsupported format: \(rawFormat)")
            }
            cfg.outputFormat = format
        }

        if normalized(form.fields["channels"] ?? "rgba") == "alpha" {
            cfg.maskOnly = true
        }

        if truthy(form.fields["crop"]) {
            cfg.cropToSubject = true
        }
        if let margin = form.fields["crop_margin"], !margin.isEmpty {
            let parsed = try parsePadding(margin)
            cfg.padding = parsed.value
            cfg.paddingIsPercent = parsed.isPercent
        }
        if truthy(form.fields["add_shadow"]) {
            cfg.dropShadow = true
        }

        cfg.algo = try parseAlgorithm(type: form.fields["type"])

        if let bgColor = form.fields["bg_color"], !bgColor.isEmpty {
            cfg.background = .solidColor(try ColourParser.parse(normalizedColor(bgColor)))
        } else if let bgFile = form.files["bg_image_file"] {
            guard let backgroundImagePath else {
                throw BgBgOneError.userError("internal server error: missing background image path")
            }
            if bgFile.data.isEmpty {
                throw BgBgOneError.userError("bg_image_file is empty")
            }
            cfg.background = .image(backgroundImagePath)
        } else if let bgB64 = form.fields["bg_image_file_b64"], !bgB64.isEmpty {
            guard backgroundImagePath != nil else {
                throw BgBgOneError.userError("internal server error: missing background image path")
            }
            cfg.background = .image(backgroundImagePath!)
        }

        return ServerRemovalRequest(input: input, config: cfg, responseKind: responseKind)
    }

    private static func parseInput(_ form: ServerForm) throws -> ServerInputSource {
        if let file = form.files["image_file"] {
            guard !file.data.isEmpty else {
                throw BgBgOneError.userError("image_file is empty")
            }
            return .uploaded(file.data, filename: file.filename.isEmpty ? "image" : file.filename)
        }
        if let encoded = form.fields["image_file_b64"], !encoded.isEmpty {
            guard let data = Data(base64Encoded: encoded), !data.isEmpty else {
                throw BgBgOneError.userError("image_file_b64 is not valid base64 image data")
            }
            return .uploaded(data, filename: "image")
        }
        throw BgBgOneError.userError("missing image_file upload")
    }

    private static func parseAlgorithm(type: String?) throws -> Algo {
        switch normalized(type ?? "auto") {
        case "", "auto", "product", "car":
            return .auto
        case "person":
            return .person
        case "saliency":
            return .saliency
        case "vn-mask":
            return .vnMask
        default:
            throw BgBgOneError.parser("unsupported type: \(type ?? "")")
        }
    }

    private static func parsePadding(_ raw: String) throws -> (value: Double, isPercent: Bool) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasSuffix("%") {
            let body = String(trimmed.dropLast())
            guard let n = Double(body), n >= 0 else {
                throw BgBgOneError.parser("invalid crop_margin: \(raw)")
            }
            return (n / 100.0, true)
        }
        guard let n = Double(trimmed), n >= 0 else {
            throw BgBgOneError.parser("invalid crop_margin: \(raw)")
        }
        return (n, false)
    }

    private static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func normalizedColor(_ value: String) -> String {
        let raw = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.hasPrefix("#") || raw.hasPrefix("rgb:") || raw.hasPrefix("rgba:") {
            return raw
        }
        if raw.allSatisfy(\.isHexDigit), [3, 4, 6, 8].contains(raw.count) {
            return "#\(raw)"
        }
        return raw
    }

    private static func truthy(_ value: String?) -> Bool {
        switch normalized(value ?? "") {
        case "1", "true", "yes", "y", "on":
            return true
        default:
            return false
        }
    }
}
