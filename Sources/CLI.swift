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

        BACKGROUND:
          --bg color:<#hex|named|rgb:r,g,b>     solid colour
          --bg image:<path>                     image file
          --bg-fit cover|contain|tile|center    fit mode for image backgrounds

        MATTE / EDGE:
          --mask-only                           output the alpha mask only
          --feather <px>                        edge softening (default: 1)
          --threshold <0..1>                    mask binarisation
          --padding <px|N%>                     extra space around subject
          --crop                                tight-crop to subject bbox
          --shadow                              drop shadow under cutout

        ALGORITHM:
          --algo auto|vn-mask|person|saliency   (default: auto)
          auto uses the public foreground-instance mask API.

        MULTI-INSTANCE:
          --multi                               one file per detected instance
          --instance-naming "{base}-{n}.{ext}"  filename template

        OUTPUT:
          --to png|jpg|heic|avif|tiff           output format (default: png)
          --quality 1..100                      for lossy formats (default: 92)
          -o, --output <path>                   explicit output file
          --out-dir <dir>                       batch output directory

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

        Output formats:        png, jpg, heic, avif, tiff

        Backgrounds:
          color                always available
          image                always available

        Pipeline:
          network              hard-blocked at runtime
        """)
    }
}
