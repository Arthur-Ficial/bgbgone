import Foundation

public enum ServerResponseKind: Sendable, Equatable {
    case image
    case json
    case zip
}

public enum ServerInputSource: Sendable, Equatable {
    case uploaded(Data, filename: String)
}

public struct ServerRemovalRequest: Sendable, Equatable {
    public var input: ServerInputSource
    public var config: Config
    public var responseKind: ServerResponseKind
    public var typeHeaderValue: String?

    public static func parse(
        form: ServerForm,
        inputPath: String,
        backgroundImagePath: String?,
        acceptHeader: String? = nil
    ) throws -> ServerRemovalRequest {
        try validateKnownFields(form)
        try validateSourceCount(form)
        try validateBackgroundSourceCount(form)

        let input = try parseInput(form)
        var cfg = Config(mode: .process)
        cfg.inputs = [inputPath]
        cfg.output = nil
        cfg.outputDir = nil
        cfg.autoFileOutput = false
        cfg.quiet = true

        let background = try parseBackground(form: form, backgroundImagePath: backgroundImagePath)
        cfg.background = background

        let responseKind = try parseFormat(form: form, acceptHeader: acceptHeader, background: background, cfg: &cfg)
        try parseChannels(form: form, cfg: &cfg)

        let rawSize = form.fields["size"]
        cfg.maxOutputMegapixels = try ParameterParser.parseSize(rawSize, outputFormat: cfg.outputFormat)
        cfg.quality = try ParameterParser.parseQuality(form.fields["quality"])
        if let bgFit = try ParameterParser.parseBgFit(form.fields["bg-fit"]) {
            cfg.bgFit = bgFit
        }

        let typeValue = try parseAlgorithmAndType(form: form, cfg: &cfg)
        let typeHeader = try parseTypeHeader(form: form, typeValue: typeValue)

        cfg.roi = try ParameterParser.parseROI(form.fields["roi"])
        let crop = try ParameterParser.parseBoolean(
            form.fields["crop"],
            default: false,
            code: "invalid_crop",
            title: "Invalid crop parameter given"
        )
        cfg.cropToSubject = crop
        cfg.cropMargins = try ParameterParser.parseCropMargins(form.fields["crop-margin"])

        cfg.semitransparency = try ParameterParser.parseBoolean(
            form.fields["semitransparency"],
            default: true,
            code: "invalid_semitransparency",
            title: "Invalid semitransparency parameter given"
        )

        try parseShadow(form: form, cfg: &cfg)

        // T59 #61 - HTTP filter chain parity with the CLI --filter flag.
        if let raw = form.fields["filter"], !raw.isEmpty {
            do {
                let chain = try FilterParser.parse(raw)
                try FilterRegistry.validate(chain)
                if !chain.isEmpty { cfg.filters.append(chain) }
            } catch let e as BgBgOneError {
                throw ParameterParseError.invalid("invalid_filter", e.message)
            }
        }

        return ServerRemovalRequest(input: input, config: cfg, responseKind: responseKind, typeHeaderValue: typeHeader)
    }

    private static func validateKnownFields(_ form: ServerForm) throws {
        let allowedFields: Set<String> = [
            "image_file",
            "bg",
            "format",
            "channels",
            "size",
            "quality",
            "bg-fit",
            "type",
            "type-level",
            "roi",
            "crop",
            "crop-margin",
            "semitransparency",
            "shadow-type",
            "shadow-opacity",
            "filter",
        ]
        let allowedFiles: Set<String> = ["image_file", "bg"]
        if let unknown = form.fields.keys.first(where: { !allowedFields.contains($0) }) {
            throw ParameterParseError.invalid("unknown_field", "Unknown field '\(unknown)'")
        }
        if let unknown = form.files.keys.first(where: { !allowedFiles.contains($0) }) {
            throw ParameterParseError.invalid("unknown_file_field", "Unknown file field '\(unknown)'")
        }
    }

    private static func validateSourceCount(_ form: ServerForm) throws {
        let sources = [
            form.files["image_file"] != nil,
            present(form.fields["image_file"])
        ].filter { $0 }.count
        if sources == 0 {
            throw ParameterParseError.invalid(
                "missing_source",
                "No image given",
                detail: "Provide image_file as a multipart file or base64 text field."
            )
        }
        if sources > 1 {
            throw ParameterParseError.invalid(
                "multiple_sources",
                "Multiple image sources given: provide image_file as either a file part or a base64 text field."
            )
        }
    }

    private static func validateBackgroundSourceCount(_ form: ServerForm) throws {
        let sources = [
            present(form.fields["bg"]),
            form.files["bg"] != nil
        ].filter { $0 }.count
        if sources > 1 {
            throw ParameterParseError.invalid(
                "multiple_bg_sources",
                "Multiple background sources given: provide either bg=<color:...|image:...> or a bg file part."
            )
        }
    }

    private static func parseInput(_ form: ServerForm) throws -> ServerInputSource {
        if let file = form.files["image_file"] {
            guard !file.data.isEmpty else {
                throw ParameterParseError.invalid("invalid_file", "image_file is empty")
            }
            return .uploaded(file.data, filename: file.filename.isEmpty ? "image" : file.filename)
        }
        if let encoded = form.fields["image_file"], !encoded.isEmpty {
            guard let data = Data(base64Encoded: encoded), !data.isEmpty else {
                throw ParameterParseError.invalid("invalid_file", "image_file is not valid base64 image data")
            }
            return .uploaded(data, filename: "image")
        }
        throw ParameterParseError.invalid("missing_source", "No image given")
    }

    private static func parseBackground(form: ServerForm, backgroundImagePath: String?) throws -> Background {
        if let bg = form.fields["bg"], !bg.isEmpty {
            do {
                return try ConfigBuilder.parseBackground(bg)
            } catch {
                throw ParameterParseError.invalid("invalid_bg", "Invalid bg parameter given")
            }
        }
        if let bgFile = form.files["bg"] {
            guard let backgroundImagePath else {
                throw ParameterParseError.invalid("invalid_bg", "Missing background image file")
            }
            if bgFile.data.isEmpty {
                throw ParameterParseError.invalid("invalid_bg", "bg file is empty")
            }
            return .image(backgroundImagePath)
        }
        return .transparent
    }

    private static func parseFormat(form: ServerForm, acceptHeader: String?, background: Background, cfg: inout Config) throws -> ServerResponseKind {
        let rawFormat = ParameterParser.normalize(form.fields["format"] ?? "auto")
        let wantsJSON = rawFormat == "json" || (acceptHeader ?? "").lowercased().contains("application/json")
        if wantsJSON {
            cfg.outputFormat = .png
            return .json
        }

        switch rawFormat {
        case "", "auto":
            cfg.outputFormat = isOpaque(background: background) ? .jpeg : .png
            return .image
        case "zip":
            cfg.outputFormat = .zip
            return .zip
        case "png", "jpg", "heic", "avif", "tiff":
            let format = OutputFormat.parseCanonical(rawFormat)!
            cfg.outputFormat = format
            return .image
        default:
            throw ParameterParseError.invalid("invalid_format", "Invalid format parameter given")
        }
    }

    private static func parseChannels(form: ServerForm, cfg: inout Config) throws {
        switch ParameterParser.normalize(form.fields["channels"] ?? "rgba") {
        case "", "rgba":
            break
        case "alpha":
            cfg.maskOnly = true
            cfg.outputFormat = .png
        default:
            throw ParameterParseError.invalid("invalid_channels", "Invalid value for parameter 'channels'")
        }
    }

    private static func parseAlgorithmAndType(form: ServerForm, cfg: inout Config) throws -> String {
        let parsed = try ParameterParser.parseForegroundType(form.fields["type"])
        cfg.algo = parsed.algo
        return parsed.typeValue
    }

    private static func parseTypeHeader(form: ServerForm, typeValue: String) throws -> String? {
        let level = ParameterParser.normalize(form.fields["type-level"] ?? "1")
        switch level {
        case "none":
            return nil
        case "", "1", "2", "latest":
            return typeValue
        default:
            throw ParameterParseError.invalid("invalid_type_level", "Invalid type-level parameter given")
        }
    }

    private static func parseShadow(form: ServerForm, cfg: inout Config) throws {
        if let raw = form.fields["shadow-type"] {
            switch ParameterParser.normalize(raw) {
            case "none":
                cfg.dropShadow = false
            case "auto", "drop", "3d", "car":
                cfg.dropShadow = true
            default:
                throw ParameterParseError.invalid("invalid_shadow_type", "Invalid shadow-type parameter given")
            }
        }
        cfg.shadowOpacity = try ParameterParser.parseShadowOpacity(form.fields["shadow-opacity"])
    }

    private static func isOpaque(background: Background) -> Bool {
        switch background {
        case .transparent:
            return false
        case .image:
            return true
        case .solidColor(let rgba):
            return rgba.a >= 1.0
        }
    }

    private static func present(_ value: String?) -> Bool {
        guard let value else { return false }
        return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
