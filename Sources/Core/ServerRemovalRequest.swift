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
        try validateSourceCount(form)
        try validateBackgroundSourceCount(form)

        if present(form.fields["image_url"]) {
            throw ServerAPIError.notImplementable("remote image_url cannot be fetched by the local no-network runtime")
        }
        if present(form.fields["bg_image_url"]) {
            throw ServerAPIError.notImplementable("remote bg_image_url cannot be fetched by the local no-network runtime")
        }

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
        cfg.maxOutputMegapixels = try ServerCompatibilityParser.parseSize(rawSize, outputFormat: cfg.outputFormat)

        let typeValue = try parseAlgorithmAndType(form: form, cfg: &cfg)
        let typeHeader = try parseTypeHeader(form: form, typeValue: typeValue)

        cfg.roi = try ServerCompatibilityParser.parseROI(form.fields["roi"])
        let crop = try ServerCompatibilityParser.parseBoolean(
            form.fields["crop"],
            default: false,
            code: "invalid_crop",
            title: "Invalid crop parameter given"
        )
        cfg.cropToSubject = crop
        cfg.cropMargins = try ServerCompatibilityParser.parseCropMargins(form.fields["crop_margin"])
        if cfg.cropMargins == nil, let margin = form.fields["crop_margin"], !margin.isEmpty {
            let parsed = try parseLegacyPadding(margin)
            cfg.padding = parsed.value
            cfg.paddingIsPercent = parsed.isPercent
        }

        cfg.scalePercent = try ServerCompatibilityParser.parseScale(form.fields["scale"])
        cfg.position = try ServerCompatibilityParser.parsePosition(form.fields["position"], scalePercent: cfg.scalePercent)
        cfg.semitransparency = try ServerCompatibilityParser.parseBoolean(
            form.fields["semitransparency"],
            default: true,
            code: "invalid_semitransparency",
            title: "Invalid semitransparency parameter given"
        )

        try parseShadow(form: form, cfg: &cfg)

        return ServerRemovalRequest(input: input, config: cfg, responseKind: responseKind, typeHeaderValue: typeHeader)
    }

    private static func validateSourceCount(_ form: ServerForm) throws {
        let sources = [
            form.files["image_file"] != nil,
            present(form.fields["image_file_b64"]),
            present(form.fields["image_url"])
        ].filter { $0 }.count
        if sources == 0 {
            throw ServerAPIError.invalid(
                "missing_source",
                "No image given",
                detail: "Please provide the source image in the image_url, image_file or image_file_b64 parameter."
            )
        }
        if sources > 1 {
            throw ServerAPIError.invalid(
                "multiple_sources",
                "Multiple image sources given: Please provide either the image_url, image_file or image_file_b64 parameter."
            )
        }
    }

    private static func validateBackgroundSourceCount(_ form: ServerForm) throws {
        let sources = [
            present(form.fields["bg_color"]),
            form.files["bg_image_file"] != nil,
            present(form.fields["bg_image_file_b64"]),
            present(form.fields["bg_image_url"])
        ].filter { $0 }.count
        if sources > 1 {
            throw ServerAPIError.invalid(
                "multiple_bg_sources",
                "Multiple background sources given: Please provide either the bg_color, the bg_image_url or the bg_image_file parameter."
            )
        }
    }

    private static func parseInput(_ form: ServerForm) throws -> ServerInputSource {
        if let file = form.files["image_file"] {
            guard !file.data.isEmpty else {
                throw ServerAPIError.invalid("invalid_file", "image_file is empty")
            }
            return .uploaded(file.data, filename: file.filename.isEmpty ? "image" : file.filename)
        }
        if let encoded = form.fields["image_file_b64"], !encoded.isEmpty {
            guard let data = Data(base64Encoded: encoded), !data.isEmpty else {
                throw ServerAPIError.invalid("invalid_file", "image_file_b64 is not valid base64 image data")
            }
            return .uploaded(data, filename: "image")
        }
        throw ServerAPIError.invalid("missing_source", "No image given")
    }

    private static func parseBackground(form: ServerForm, backgroundImagePath: String?) throws -> Background {
        if let bgColor = form.fields["bg_color"], !bgColor.isEmpty {
            do {
                return .solidColor(try ColourParser.parse(normalizedColor(bgColor)))
            } catch {
                throw ServerAPIError.invalid("invalid_bg_color", "Invalid bg_color parameter given")
            }
        }
        if let bgFile = form.files["bg_image_file"] {
            guard let backgroundImagePath else {
                throw ServerAPIError.invalid("invalid_bg_image_file", "Missing background image file")
            }
            if bgFile.data.isEmpty {
                throw ServerAPIError.invalid("invalid_bg_image_file", "bg_image_file is empty")
            }
            return .image(backgroundImagePath)
        }
        if let bgB64 = form.fields["bg_image_file_b64"], !bgB64.isEmpty {
            guard backgroundImagePath != nil else {
                throw ServerAPIError.invalid("invalid_bg_image_file", "bg_image_file_b64 is not valid base64 image data")
            }
            return .image(backgroundImagePath!)
        }
        return .transparent
    }

    private static func parseFormat(form: ServerForm, acceptHeader: String?, background: Background, cfg: inout Config) throws -> ServerResponseKind {
        let rawFormat = ServerCompatibilityParser.normalize(form.fields["format"] ?? "auto")
        let wantsJSON = rawFormat == "json" || (acceptHeader ?? "").lowercased().contains("application/json")
        if wantsJSON {
            cfg.outputFormat = .png
            return .json
        }

        switch rawFormat {
        case "", "auto":
            cfg.outputFormat = isOpaque(background: background) ? .jpeg : .png
            return .image
        case "png":
            cfg.outputFormat = .png
            return .image
        case "jpg", "jpeg":
            cfg.outputFormat = .jpeg
            return .image
        case "zip":
            cfg.outputFormat = .zip
            return .zip
        case "webp":
            throw ServerAPIError.notImplementable("webp output requires an encoder unavailable in this zero-dependency build")
        case "heic", "heif", "avif", "tif", "tiff":
            guard let format = OutputFormat.parse(rawFormat) else {
                throw ServerAPIError.invalid("invalid_format", "Invalid format parameter given")
            }
            cfg.outputFormat = format
            return .image
        default:
            throw ServerAPIError.invalid("invalid_format", "Invalid format parameter given")
        }
    }

    private static func parseChannels(form: ServerForm, cfg: inout Config) throws {
        switch ServerCompatibilityParser.normalize(form.fields["channels"] ?? "rgba") {
        case "", "rgba":
            break
        case "alpha":
            cfg.maskOnly = true
            cfg.outputFormat = .png
        default:
            throw ServerAPIError.invalid("invalid_channels", "Invalid value for parameter 'channels'")
        }
    }

    private static func parseAlgorithmAndType(form: ServerForm, cfg: inout Config) throws -> String {
        let type = ServerCompatibilityParser.normalize(form.fields["type"] ?? "auto")
        switch type {
        case "", "auto":
            cfg.algo = .auto
            return "other"
        case "person":
            cfg.algo = .person
            return "person"
        case "product", "car", "animal", "graphic", "transportation":
            cfg.algo = .auto
            return type
        case "saliency":
            cfg.algo = .saliency
            return "other"
        case "vn-mask":
            cfg.algo = .vnMask
            return "other"
        default:
            throw ServerAPIError.invalid("invalid_type", "Invalid type parameter given")
        }
    }

    private static func parseTypeHeader(form: ServerForm, typeValue: String) throws -> String? {
        let level = ServerCompatibilityParser.normalize(form.fields["type_level"] ?? "1")
        switch level {
        case "none":
            return nil
        case "", "1", "2", "latest":
            return typeValue
        default:
            throw ServerAPIError.invalid("invalid_type_level", "Invalid type_level parameter given")
        }
    }

    private static func parseShadow(form: ServerForm, cfg: inout Config) throws {
        let hasAddShadow = present(form.fields["add_shadow"])
        let hasShadowType = present(form.fields["shadow_type"])
        if hasAddShadow && hasShadowType {
            throw ServerAPIError.invalid(
                "multiple_shadow_params",
                "Multiple shadow parameters given: Please provide either the add_shadow or the shadow_type parameter."
            )
        }

        if hasAddShadow {
            cfg.dropShadow = try ServerCompatibilityParser.parseBoolean(
                form.fields["add_shadow"],
                default: false,
                code: "invalid_shadow",
                title: "Invalid add_shadow parameter given"
            )
        } else if hasShadowType {
            switch ServerCompatibilityParser.normalize(form.fields["shadow_type"] ?? "") {
            case "none":
                cfg.dropShadow = false
            case "auto", "drop", "3d", "car":
                cfg.dropShadow = true
            default:
                throw ServerAPIError.invalid("invalid_shadow_type", "Invalid shadow_type parameter given")
            }
        }

        cfg.shadowOpacity = try ServerCompatibilityParser.parseShadowOpacity(form.fields["shadow_opacity"])
    }

    private static func parseLegacyPadding(_ raw: String) throws -> (value: Double, isPercent: Bool) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasSuffix("%") {
            let body = String(trimmed.dropLast())
            guard let n = Double(body), n >= 0 else {
                throw ServerAPIError.invalid("invalid_crop_margin", "Invalid crop_margin parameter given")
            }
            return (n / 100.0, true)
        }
        let px = trimmed.lowercased().hasSuffix("px") ? String(trimmed.dropLast(2)) : trimmed
        guard let n = Double(px), n >= 0 else {
            throw ServerAPIError.invalid("invalid_crop_margin", "Invalid crop_margin parameter given")
        }
        return (n, false)
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

    private static func present(_ value: String?) -> Bool {
        guard let value else { return false }
        return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
