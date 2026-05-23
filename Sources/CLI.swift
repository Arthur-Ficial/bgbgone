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
          • -o out.jpg or > out.jpg selects JPEG when macOS exposes the stdout file path
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
          --bg-color <spec>                     shared solid colour field
          --bg-image <path>                     shared background image field
          --bg-fit cover|contain|tile|center    fit mode for image backgrounds

        MATTE / EDGE:
          --mask-only                           output the alpha mask only
          --channels rgba|alpha                 finalized image or alpha mask
          --feather <px>                        edge softening (default: 1)
          --threshold <0..1>                    mask binarisation
          --padding <px|N%>                     extra space around subject
          --crop-margin <1|2|4 values>          API-style crop margins (px or %)
          --crop                                tight-crop to subject bbox
          --roi "x1 y1 x2 y2"                   keep detections inside region of interest
          --scale <10%..100%|original>          scale subject on the canvas
          --position <center|x% y%|original>    place scaled subject on the canvas
          --semitransparency true|false         keep or harden semi-transparent matte pixels
          --shadow                              drop shadow under cutout
          --shadow-type auto|drop|3D|car|none   shadow compatibility selector
          --shadow-opacity <0..100|auto>        shadow darkness

        ALGORITHM:
          --algo auto|vn-mask|person|saliency   (default: auto)
          --type auto|person|product|car|animal|graphic|transportation
          auto uses the public foreground-instance mask API.

        FILTER (epic #1, in progress):
          --filter "<chain>"                    FFmpeg-style filter chain (repeatable)
          chain  := stage (";" stage)*
          stage  := [layer ":"] filter ("," filter)*
          layer  := fg | bg | all | mask        (default: all)
          filter := name ("=" arg (":" arg)*)?
          examples:
            --filter "bg:grayscale"
            --filter "bg:blur=20"
            --filter "fg:outline=color=#fff:width=3,shadow=blur=12:opacity=0.5"
          run `bgbgone --filters-list` to discover available filters.

        MULTI-INSTANCE:
          --multi                               one file per detected instance (file input only)
          --instance-naming "{base}-{n}.{ext}"  filename template

        OUTPUT:
          --to, --format png|jpg|zip|heic|avif|tiff
                                                 output format (default: png)
          --size preview|full|50MP|auto         optional output megapixel cap
          --quality 1..100                      for lossy formats (default: 92)
          -o, --output <path>                   explicit output file
          --out-dir <dir>                       batch output directory

        ROUTING RULES:
          -o and --out-dir are mutually exclusive
          stdin input requires stdout or -o; --out-dir needs file inputs
          --multi writes files; it cannot combine with -o or --mask-only

        SERVER:
          --server                             run local HTTP API
          --host <addr>                        bind address (default: 127.0.0.1)
          --port <n>                           bind port (default: 8787)
          --cors                               enable CORS headers for allowed origins
          --allowed-origins <csv>              add allowed browser origins
          --no-origin-check | --footgun        disable browser origin checks
          --token <secret> | --token-auto      require Bearer token
          --public-health                      keep /health public on non-loopback binds
          --max-body-mb <n>                    request body limit (default: 32)

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
            let aliasStr = entry.aliases.isEmpty ? "" : " (aliases: \(entry.aliases.sorted().joined(separator: ", ")))"
            print("  \(entry.name)\(aliasStr)")
            print("    layers:    \(layers)")
            print("    signature: \(entry.signature)")
            print("    doc:       \(entry.doc)")
            if entry.producesAlpha {
                print("    note:      can introduce alpha; use PNG output or --bg")
            }
            print("")
        }
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

        Output formats:        png, jpg, zip, heic, avif, tiff

        Backgrounds:
          color                always available
          image                always available

        Pipeline:
          network              hard-blocked at runtime
        """)
    }
}
