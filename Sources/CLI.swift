import Foundation
import BgBgOneCore

enum CLI {

    static func printVersion() {
        print("bgbgone v\(buildVersion)")
    }

    static func printHelp() {
        let appName = (CommandLine.arguments.first.map { ($0 as NSString).lastPathComponent }) ?? "bgbgone"
        print("""
        bgbgone v\(buildVersion) — the ultimate UNIX-style background remover
                                   (100% on-device, Apple Vision)

        USAGE:
          \(appName) [OPTIONS] [INPUT...]

        DEFAULTS:
          • \(appName) photo.jpg writes photo_bgbgone.png when stdout is a terminal
          • \(appName) photo.jpg > out.png writes image bytes to stdout
          • -o out.jpg, -o -, or > out.jpg select the destination
          • opaque-only formats use a white background unless --bg is set

        EXAMPLES:
          \(appName) in.jpg                             # creates in_bgbgone.png
          \(appName) in.jpg > out.png                   # transparent PNG cutout
          \(appName) in.jpg -o out.png                  # to file
          \(appName) in.jpg -o out.jpg                  # JPEG on white
          \(appName) in.jpg --bg color:#fff -o w.png    # white background
          \(appName) in.jpg --bg image:bg.jpg           # image background
          \(appName) *.jpg --out-dir ./cutouts          # batch
          cat in.png | \(appName) > out.png             # pipe in / pipe out
          \(appName) --server                           # local HTTP API on 127.0.0.1:8787

        BACKGROUND:
          --bg color:<#hex|named|rgb:r,g,b>     solid colour
          --bg image:<path>                     image file
          --bg-fit cover|contain|tile|center    fit mode for image backgrounds

        MATTE / EDGE:
          --channels rgba|alpha                 finalized image or alpha mask
          --crop                                tight-crop to subject bbox
          --crop-margin <1|2|4 px or %>         margins around the crop
          --roi "x1 y1 x2 y2"                   keep detections inside region of interest
          --semitransparency true|false         keep or harden semi-transparent matte pixels
          --shadow-type auto|drop|3D|car|none   shadow preset (none = no shadow)
          --shadow-opacity <0..100|auto>        shadow darkness
          (use --filter "mask:feather=N", "mask:threshold=N", "fg:scale=F",
           "fg:translate=X,Y", or --channels alpha in place of removed flags)

        ALGORITHM:
          --type \(CLIContract.choices(CLIContract.subjectTypes))
                                                (default: auto)
          Subject hints (product/car/animal/graphic/transportation) and the
          direct names (vn-mask/person/saliency) map to one Vision algorithm.
          The same value is accepted by the server `type` field.

        FILTER:
          --filter "<chain>"                    FFmpeg-style filter chain (repeatable)
          chain  := stage (";" stage)*
          stage  := [layer ":"] filter ("," filter)*
          layer  := fg | bg | all | mask | composite
          filter := name ("=" arg (":" arg)*)?
          colour args accept #hex, named colours, rgb:R,G,B, rgba:R,G,B,A
          examples:
            --filter "bg:grayscale"
            --filter "bg:blur=20"
            --filter "fg:outline=color=#fff:width=3,shadow=blur=12:opacity=0.5"
            --filter "bg:sepia=1;composite:vignette=1.8:1.1"
          run `bgbgone --help filters` or `bgbgone --help filter=blur`.

        MULTI-INSTANCE:
          --multi                               one file per detected instance (file input only)
          --instance-naming "{base}-{n}.{ext}"  filename template

        OUTPUT:
          --format \(CLIContract.choices(CLIContract.outputFormats))
                                                 output format (default: png)
          --size preview|full|50MP|auto         optional output megapixel cap
          --quality 1..100                      for lossy formats (default: 92)
          -o, --output <path>                   explicit output file
          --out-dir <dir>                       batch output directory

        ROUTING RULES:
          -o and --out-dir are mutually exclusive
          stdin input requires stdout or -o; --out-dir needs file inputs
          --multi writes files; it cannot combine with -o

        SERVER:
          --server                             run local HTTP API
          --host <addr>                        bind address (default: \(CLIContract.serverDefaultHost))
          --port <n>                           bind port (default: \(CLIContract.serverDefaultPort))
          --cors                               enable CORS headers for allowed origins
          --allowed-origins <csv>              add allowed browser origins
          --no-origin-check | --footgun        disable browser origin checks
          --token <secret> | --token-auto      require Bearer token
          --public-health                      keep /health public on non-loopback binds
          --max-body-mb <n>                    request body limit (default: \(CLIContract.serverDefaultMaxBodyMB))

        META:
          --json | --ndjson                     structured output
          --quiet | --verbose
          --version | --help | -h
          --check                               capability report

        EXIT CODES:
          0  success
          1  user error (bad input, refusing TTY)
          2  parser error or no result
          3  framework error (Vision unavailable)

        100% on-device. No network. No API keys. No deps.
        Source: https://github.com/Arthur-Ficial/bgbgone
        """)
    }

    static func printFiltersList() {
        print("bgbgone v\(buildVersion) - filter catalogue (\(FilterRegistry.all.count) filters)")
        print("")
        let sorted = FilterRegistry.all.sorted { $0.name < $1.name }
        for entry in sorted {
            let layers = entry.validLayers.map { $0.rawValue }.sorted().joined(separator: "|")
            print("  \(entry.name)")
            print("    layers:    \(layers)")
            print("    signature: \(entry.signature)")
            print("    doc:       \(entry.doc)")
            let schema = FilterRegistry.schema(for: entry.name)
            let args = schemaDescription(schema)
            if !args.isEmpty {
                print("    args:      \(args)")
            }
            if !schema.examples.isEmpty {
                print("    examples:  \(schema.examples.joined(separator: " | "))")
            }
            if entry.producesAlpha {
                print("    note:      can introduce alpha; use PNG output or --bg")
            }
            print("")
        }
    }

    /// Machine-readable filter catalogue. Drives all auto-generated docs
    /// (per-filter pages, README filter index) so the docs cannot drift from
    /// the binary. Schema is stable and the array is sorted by `name` for
    /// byte-deterministic output.
    static func printFiltersListJSON() {
        struct JSONArg: Encodable {
            let key: String?
            let kind: String
            let `default`: String?
            let min: Double?
            let max: Double?
            let choices: [String]?
        }
        struct JSONEntry: Encodable {
            let name: String
            let layers: [String]
            let signature: String
            let doc: String
            let producesAlpha: Bool
            let positional: [JSONArg]
            let keyed: [JSONArg]
            let examples: [String]
        }
        func argJSON(_ spec: FilterArgSchema) -> JSONArg {
            let kindStr: String
            var choices: [String]? = nil
            switch spec.kind {
            case .number: kindStr = "number"
            case .color: kindStr = "color"
            case .point: kindStr = "point"
            case .choice(let ch): kindStr = "choice"; choices = ch
            }
            return JSONArg(
                key: spec.key,
                kind: kindStr,
                default: spec.defaultValue,
                min: spec.range?.lowerBound,
                max: spec.range?.upperBound,
                choices: choices
            )
        }
        let entries = FilterRegistry.all
            .sorted { $0.name < $1.name }
            .map { entry -> JSONEntry in
                let schema = FilterRegistry.schema(for: entry.name)
                return JSONEntry(
                    name: entry.name,
                    layers: entry.validLayers.map { $0.rawValue }.sorted(),
                    signature: entry.signature,
                    doc: entry.doc,
                    producesAlpha: entry.producesAlpha,
                    positional: schema.positional.map(argJSON),
                    keyed: schema.keyed.map(argJSON),
                    examples: schema.examples
                )
            }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let data = try encoder.encode(entries)
            if let s = String(data: data, encoding: .utf8) { print(s) }
        } catch {
            FileHandle.standardError.write(Data("bgbgone: failed to encode filter catalogue as JSON\n".utf8))
            exit(3)
        }
    }

    static func printFilterHelp(name raw: String) {
        guard let entry = FilterRegistry.find(raw) else {
            print("bgbgone: unknown filter \(raw)")
            exit(2)
        }
        let layers = entry.validLayers.map { $0.rawValue }.sorted().joined(separator: "|")
        let schema = FilterRegistry.schema(for: entry.name)
        print("""
        bgbgone filter: \(entry.name)
          layers:    \(layers)
          signature: \(entry.signature)
          doc:       \(entry.doc)
        """)
        let args = schemaDescription(schema)
        if !args.isEmpty {
            print("  args:      \(args)")
        }
        if !schema.examples.isEmpty {
            print("  examples:")
            let exampleLayer = entry.validLayers.map { $0.rawValue }.sorted().first ?? "all"
            for example in schema.examples {
                print("    --filter \"\(exampleLayer):\(example)\"")
            }
        }
    }

    private static func schemaDescription(_ schema: FilterSchema) -> String {
        let specs = (schema.positional + schema.keyed).map { spec -> String in
            var text = spec.key ?? "<value>"
            if let def = spec.defaultValue { text += " default=\(def)" }
            if let range = spec.range { text += " range=\(format(range.lowerBound))..\(format(range.upperBound))" }
            switch spec.kind {
            case .number:
                text += " type=number"
            case .color:
                text += " type=colour"
            case .point:
                text += " type=X,Y"
            case .choice(let choices):
                text += " choices=\(choices.joined(separator: "|"))"
            }
            return text
        }
        return specs.joined(separator: "; ")
    }

    private static func format(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(value)
    }

    static func printCheck() {
        let proc = ProcessInfo.processInfo
        let osv = proc.operatingSystemVersion
        let os = "macOS \(osv.majorVersion).\(osv.minorVersion).\(osv.patchVersion)"
        let foregroundMaskAvailable = CapabilityProbe.isVNForegroundInstanceMaskAvailable()
        let personAvailable = CapabilityProbe.isVNPersonSegmentationAvailable()
        let saliencyAvailable = CapabilityProbe.isVNSaliencyAvailable()
        print("""
        bgbgone v\(buildVersion) capability report
          OS:                  \(os)
          Built on:            \(buildOS) (\(buildDate))
          Swift:               \(buildSwiftVersion)
          Commit:              \(buildCommit) (\(buildBranch))

        Algorithms:
          vn-mask              \(foregroundMaskAvailable ? "available" : "unavailable") (foreground-instance mask, macOS 14+)
          person               \(personAvailable ? "available" : "unavailable") (Vision person segmentation, macOS 12+)
          saliency             \(saliencyAvailable ? "available" : "unavailable") (Vision objectness saliency, macOS 10.15+)

        Output formats:        \(CLIContract.outputFormats.joined(separator: ", "))

        Backgrounds:
          color                always available
          image                always available

        Pipeline:
          network              hard-blocked at runtime
        """)
    }
}
