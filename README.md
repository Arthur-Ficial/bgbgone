# bgbgone

[![Version 0.1.23](https://img.shields.io/badge/version-0.1.23-blue)](https://github.com/Arthur-Ficial/bgbgone)
[![Swift 6.3+](https://img.shields.io/badge/Swift-6.3%2B-F05138?logo=swift&logoColor=white)](https://swift.org)
[![macOS 26+](https://img.shields.io/badge/macOS-26%2B-000000?logo=apple&logoColor=white)](https://developer.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![100% On-Device](https://img.shields.io/badge/privacy-100%25%20on--device-green)](https://developer.apple.com/documentation/vision)
[![100% Scriptable](https://img.shields.io/badge/scriptable-100%25-green)](#why)

## Background, be gone!

One shell command. Any image. Transparent cutout in 86 milliseconds. 100% on your Mac. 100% scriptable. Others sell this as a subscription, but free and open source is just cooler. A 3 MB binary you `brew install` once and own forever.

![bgbgone hero](docs/images/hero.png)

## Install

```bash
brew tap Arthur-Ficial/tap
brew install Arthur-Ficial/tap/bgbgone
```

Or from source: `make install` (builds release, installs to `/usr/local/bin`). Requires macOS 26+ and Command Line Tools. **No Xcode needed. Zero dependencies. ~3 MB binary.**

```bash
bgbgone in.jpg                                    # creates in_bgbgone.png
bgbgone in.jpg > out.png                          # transparent PNG cutout
bgbgone in.jpg --bg color:white -o on-white.png   # on a colour
bgbgone in.jpg --bg image:beach.jpg -o beach.png  # on an image
cat in.png | bgbgone > out.png                    # pipe
bgbgone *.jpg --out-dir ./out/                    # batch
```

## Why

Every Mac in 2026 ships with a small render farm of on-device image AI. Apple's [Vision framework](https://developer.apple.com/documentation/vision) exposes `VNGenerateForegroundInstanceMaskRequest`, a foundation-model-class background remover, free, on every Mac, offline. But it is only reachable from Swift. `bgbgone` wraps it as a UNIX CLI so you can use it the way you already use `sips`, `imagemagick`, or `ffmpeg`: from shell scripts, build steps, batch jobs, makefiles, and pipelines.

It works on anything with a foreground subject: photographs, paintings, spacecraft imagery, woodblock prints, vintage product advertisements. One flag, sixteen subjects, no per-image tuning:

![cutout grid, 16 PD subjects, one CLI call each](docs/images/showcase-cutouts.png)

## Quick start

```bash
bgbgone photo.jpg                                           # creates photo_bgbgone.png
bgbgone photo.jpg > cutout.png                              # to stdout
bgbgone photo.jpg -o cutout.png                             # to a file
bgbgone photo.jpg -o cutout.jpg                             # JPEG, white bg by default
bgbgone ~/photos/*.heic --out-dir ./cutouts                 # batch a folder
curl -L https://example.com/photo.jpg | bgbgone > out.png   # pipe in
cat photo.jpg | bgbgone --bg color:white > on-white.png     # pipe through
```

When stdout is a terminal and the input is a file, bgbgone writes `<stem>_bgbgone.<ext>` next to the input instead of dumping binary into the terminal. When stdout is redirected, bgbgone writes image bytes to stdout. For portable scripts, prefer `-o cutout.jpg` over `> cutout.jpg`.

---

## Examples

Every image below is produced by `bash scripts/make-readme-examples.sh` from real bgbgone invocations against the documented [strict-PD Wikimedia fixtures](Tests/fixtures/LICENSES.md). The script is the audit trail.

### Solid colour backgrounds

```bash
bgbgone in.jpg --bg color:white       -o out.png   # named
bgbgone in.jpg --bg color:black       -o out.png
bgbgone in.jpg --bg color:#0066cc     -o out.png   # hex
bgbgone in.jpg --bg color:rgb:0,200,0 -o out.png   # rgb triple
```

![--bg color across three subjects, four colour syntaxes](docs/images/showcase-colors.png)

### Image backgrounds

```bash
bgbgone in.jpg --bg image:./bg.jpg                   -o out.png
bgbgone in.jpg --bg image:./bg.jpg --bg-fit cover    -o out.png   # default
bgbgone in.jpg --bg image:./bg.jpg --bg-fit contain  -o out.png
bgbgone in.jpg --bg image:./bg.jpg --bg-fit tile     -o out.png
bgbgone in.jpg --bg image:./bg.jpg --bg-fit center   -o out.png
```

Row 1: same subject, every `--bg-fit` mode. Row 2: same subject on two different PD backgrounds.

![--bg image with each --bg-fit mode and two distinct backgrounds](docs/images/showcase-image-bg.png)

The same Mona Lisa onto six different public-domain backgrounds, one invocation each:

![Mona Lisa, six PD backgrounds, one CLI call each](docs/images/mona-lisa-tour.png)

```bash
bgbgone mona-lisa.jpg --bg color:white                       -o studio.jpg
bgbgone mona-lisa.jpg --bg color:black                       -o dark.jpg
bgbgone mona-lisa.jpg --bg image:./hubble-ngc1300.jpg        -o galaxy.jpg
bgbgone mona-lisa.jpg --bg image:./nasa-aldrin-moon.jpg      -o moon.jpg
bgbgone mona-lisa.jpg --bg image:./hokusai-great-wave.jpg    -o wave.jpg
bgbgone mona-lisa.jpg --bg image:./mars-curiosity.jpg        -o mars.jpg
```

### Edge refinement

`--feather <px>` softens the matte edge. `--crop` tight-crops to the subject's bounding box. `--padding` adds breathing room. `--shadow` drops a shadow under the cutout. `--mask-only` emits the grayscale alpha matte.

![feather progression (0 to 16 px), --crop, --padding, --shadow, --mask-only](docs/images/showcase-edges.png)

```bash
bgbgone in.jpg --bg color:white --feather 8    -o soft.png
bgbgone in.jpg --threshold 0.55                -o crisper.png
bgbgone in.jpg --crop                          -o tight.png
bgbgone in.jpg --crop --padding 10%            -o tight-padded.png
bgbgone in.jpg --bg color:white --shadow       -o dropshadow.png
bgbgone in.jpg --mask-only                     -o matte.png
```

Closer look at the matte itself. `--mask-only` writes the grayscale alpha, and the compositor blends with that:

![input, grayscale matte, composite](docs/images/mask-breakdown.png)

Pixel-level zoom on the edge for `--feather 0` vs `--feather 8`:

![--feather close-up](docs/images/feather-zoom.png)

### Algorithm selection

```bash
bgbgone in.jpg --algo auto       # public foreground-instance mask (default)
bgbgone in.jpg --algo vn-mask    # VNGenerateForegroundInstanceMaskRequest (macOS 14+)
bgbgone in.jpg --algo person     # VNGeneratePersonSegmentationRequest (macOS 12+)
bgbgone in.jpg --algo saliency   # VNGenerateObjectnessBasedSaliencyImageRequest
```

Three subjects with every supported algorithm side by side: a Mars rover, two figures in a meadow, and a painted Renaissance figure.

![--algo vn-mask, person, saliency on three subjects](docs/images/showcase-algos.png)

### Output formats

```bash
bgbgone in.jpg --to png                              # transparent PNG (default)
bgbgone in.jpg --to jpg --quality 92                 # white bg unless --bg is set
bgbgone in.jpg -o out.jpg                            # extension infers JPEG
bgbgone in.jpg --to heic
bgbgone in.jpg --to avif
bgbgone in.jpg --to tiff
```

### Multi-instance

```bash
bgbgone team.jpg --multi --out-dir ./people/
# people/team-1.png, people/team-2.png, ...

bgbgone team.jpg --multi --instance-naming "subject_{n:02}.{ext}" --out-dir ./people/
# people/subject_01.png, people/subject_02.png, ...
```

The number of instances is decided by Vision. For tightly-grouped or touching subjects (e.g. an Apollo crew shoulder-to-shoulder) Vision returns one combined instance. For subjects with visible spatial gaps you get one file per subject.

`--multi` is file-output only: it needs a file input stem for naming, cannot read image data from stdin, and cannot be combined with `-o` or `--mask-only`. If `--out-dir` is omitted, files are written beside the input image.

### Structured output

```bash
bgbgone in.jpg --json -o out.png
```

```json
{"input":"in.jpg","output":"out.png","algo":"vn-mask","format":"png","width":1280,"height":960}
```

NDJSON streams through `jq`:

```bash
ls *.jpg | xargs -I{} bgbgone {} --ndjson --out-dir ./out/ \
  | jq -s 'group_by(.algo) | map({algo: .[0].algo, n: length})'
```

### Pipe into downstream AI

A clean cutout makes downstream classifiers, embedders, and OCR more accurate. With [auge](https://github.com/Arthur-Ficial/auge):

![pipeline: bgbgone to auge with real classify output](docs/images/showcase-pipeline.png)

```bash
bgbgone Tests/fixtures/06-nasa-mars-curiosity-selfie.jpg \
    --bg color:black --to jpg -o /tmp/cut.jpg
auge --classify /tmp/cut.jpg --top 5
# machine: 52%
# toy: 12%
# figurine: 12%
# art: 10%
# statue: 10%
```

### Product photography: every step

For each vintage product fixture: source, then `--mask-only` matte, then transparent cutout, then composed onto a PD background. Same four-step pipeline, four different products.

![Products: source, mask-only, cutout, composed onto a PD background](docs/images/showcase-products.png)

```bash
bgbgone pierce-arrow-1909.jpg --mask-only                          -o matte.png
bgbgone pierce-arrow-1909.jpg                                      -o cutout.png
bgbgone pierce-arrow-1909.jpg --bg image:nasa-aldrin-moon.jpg      -o on-moon.png
```

Swap the new-background line for `--bg color:white` and you have a white-bg product-catalogue pipeline.

---

## Recipes

Catalogue an entire photo library on a white background:

```bash
for f in ~/products/*.heic; do
    bgbgone "$f" --bg color:white --to jpg --quality 92 \
        --out-dir ~/catalogue/ --json
done | jq -s 'group_by(.algo) | map({algo: .[0].algo, count: length})'
```

Brand-coloured profile picture, tight-cropped, soft edge, high-quality JPEG:

```bash
bgbgone selfie.jpg --bg color:#0066cc --crop --feather 2 \
    --to jpg --quality 95 -o linkedin-avatar.jpg
```

Sticker pack from a group photo (one PNG per detected instance):

```bash
bgbgone team-portrait.jpg --multi \
    --instance-naming "{base}-sticker-{n:02}.{ext}" \
    --out-dir ./stickers/
```

Doc-site product shot:

```bash
bgbgone product.heic --bg color:white --crop --feather 1 \
    --to jpg --quality 92 -o ./docs/product-shot.jpg
```

Chain with sibling tools. Remove the background, then classify or embed the cleaner cutout:

```bash
bgbgone photo.jpg --bg color:black --to jpg -o /tmp/x.jpg && auge --classify /tmp/x.jpg
bgbgone photo.jpg --bg color:black --to jpg -o /tmp/x.jpg && kern --embed-image /tmp/x.jpg
```

bgbgone is part of the [apfel](https://github.com/Arthur-Ficial/apfel) ecosystem of on-device CLI tools:

| Tool                                              | Capability                  | Apple framework        |
| ------------------------------------------------- | --------------------------- | ---------------------- |
| [apfel](https://github.com/Arthur-Ficial/apfel)   | LLM (text generation)       | FoundationModels       |
| [auge](https://github.com/Arthur-Ficial/auge)     | Vision / OCR (see)          | Vision                 |
| **bgbgone** (this)                                | Background removal (do)     | Vision + Core Image    |
| [ohr](https://github.com/Arthur-Ficial/ohr)       | Speech-to-text              | SpeechAnalyzer         |
| [kern](https://github.com/Arthur-Ficial/kern)     | Embeddings                  | NLContextualEmbedding  |

## Capabilities

```bash
bgbgone --check
```

```
bgbgone v0.1.20 capability report
  OS:                  macOS 26.3.1
  Algorithms:
    vn-mask            available (foreground-instance mask, macOS 14+)
    person             available (Vision person segmentation, macOS 12+)
    saliency           available (Vision objectness saliency, macOS 10.15+)
  Output formats:      png, jpg, heic, avif, tiff
  Backgrounds:
    color              always available
    image              always available
  Pipeline:
    network            hard-blocked at runtime
```

## All flags

```
USAGE:
  bgbgone [OPTIONS] [INPUT...]

DEFAULTS:
  bgbgone photo.jpg                       creates photo_bgbgone.png
  bgbgone photo.jpg > cutout.png          writes image bytes to stdout
  bgbgone photo.jpg -o cutout.jpg         infers JPEG; white bg by default

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

MULTI-INSTANCE:
  --multi                               one file per detected instance (file input only)
  --instance-naming "{base}-{n}.{ext}"  filename template (supports {n:NN})

OUTPUT:
  --to png|jpg|heic|avif|tiff           output format (default: png)
  --quality 1..100                      for lossy formats (default: 92)
  -o, --output <path>                   explicit output file
  --out-dir <dir>                       batch output directory

ROUTING RULES:
  -o and --out-dir are mutually exclusive
  stdin input requires stdout or -o; --out-dir needs file inputs
  --multi writes files; it cannot combine with -o or --mask-only

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
```

## Architecture

```
CLI args                    main.swift
   │
   ▼                        ConfigParser (pure Swift, no Apple framework deps, testable)
Config
   │
   ▼                        BgBgOne pipeline
   ├─→ ForegroundMask       Algorithms/: VNMask, Person, Saliency
   ├─→ MaskPostProcess      threshold, feather, crop, padding, --mask-only
   ├─→ Compositor           SolidColor + ImageBg
   └─→ Output               ImageIO: PNG/JPG/HEIC/AVIF/TIFF
                            NetworkGuard hard-blocks http/https/ws/wss at runtime.
```

- `BgBgOneCore` library: pure Swift, no Vision dep, unit-testable.
- Main `bgbgone` target: Vision + Core Image integration.
- `bgbgone-tests`: pure-Swift test runner (no XCTest), same pattern as [apfel](https://github.com/Arthur-Ficial/apfel) and [auge](https://github.com/Arthur-Ficial/auge).

## Performance

```bash
make test-performance-100
```

100 fixture-backed inputs, one batch process, 100 outputs verified. Latest local run: **100 images in 8.098 s, 12.35 images/s, 81.0 ms/image**, on an M-series MacBook Air. On-device, no network, no GPU contention with another process.

## Build & test

```bash
make install              # bump patch + build release + install to /usr/local/bin
make build                # bump patch + build release
make test                 # unit + integration
make test-unit            # Swift unit tests
make test-integration     # CLI e2e against strict-PD Wikimedia fixtures
make test-performance-100 # 100-image local performance scenario
make fixtures             # fetch the test fixtures (one-time)
```

### Test fixtures

The integration tests run against [16 squarely-public-domain Wikimedia images](Tests/fixtures/LICENSES.md): NASA spaceflight imagery (PD-USGov), 19th-century paintings and woodblock prints (PD-old, PD-Art), 19th and early-20th-century studio portraits (PD-old), and pre-1929 American advertisements for Singer sewing machines, the Underwood typewriter, the Edison phonograph, and the Pierce-Arrow automobile (PD-1929). No Creative Commons. Full provenance per fixture in `Tests/fixtures/LICENSES.md`.

Every example image in this README is regenerated by `scripts/make-readme-examples.sh` against a freshly-installed binary on every release. The script is the audit trail for "every README image is real."

## Design

See [`docs/design.md`](docs/design.md) for the CLI surface, algorithm selection, exit-code policy, framework version gating, and the UNIX-style contract every capability is held to.

## Privacy

- **No network.** `NetworkGuard.swift` registers a `URLProtocol` that intercepts any `http`, `https`, `ws`, or `wss` request inside the process and exits with code 3.
- **No telemetry.** No analytics, no crash reporting, no usage stats.
- **No API keys, no accounts, no subscriptions.**
- **Your images never leave your Mac.** Verifiable: run `bgbgone in.jpg` with Wi-Fi off.

## License

MIT. See [LICENSE](LICENSE).
