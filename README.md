# bgbgone

[![Version 0.1.11](https://img.shields.io/badge/version-0.1.11-blue)](https://github.com/Arthur-Ficial/bgbgone)
[![Swift 6.3+](https://img.shields.io/badge/Swift-6.3%2B-F05138?logo=swift&logoColor=white)](https://swift.org)
[![macOS 26+](https://img.shields.io/badge/macOS-26%2B-000000?logo=apple&logoColor=white)](https://developer.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![100% On-Device](https://img.shields.io/badge/privacy-100%25%20on--device-green)](https://developer.apple.com/documentation/vision)
[![100% Scriptable](https://img.shields.io/badge/scriptable-100%25-green)](#why)

The ultimate UNIX-style background remover for macOS. AI-driven via Apple's on-device Vision framework. No API keys, no cloud, no network, no subscriptions, no GUI side-effects. Pipe-friendly, scriptable, silent.

![bgbgone hero](docs/images/hero.png)

```bash
bgbgone in.jpg > out.png                          # transparent PNG cutout
bgbgone in.jpg --bg color:white -o on-white.png   # on a colour
bgbgone in.jpg --bg image:beach.jpg -o beach.png  # on an image
```

## Why

Every Mac in 2026 ships with a small render farm of on-device image AI. Apple's [Vision framework](https://developer.apple.com/documentation/vision) gives you `VNGenerateForegroundInstanceMaskRequest` — a foundation-model-class background remover, free, on every Mac, no internet required. But it's only callable from Swift. `bgbgone` wraps it as a UNIX CLI so you can use it from scripts, pipelines, batch jobs, build steps — anywhere you'd use `sips` or `imagemagick`.

It works on anything with a foreground subject — photographs, paintings, spacecraft imagery, woodblock prints, vintage product advertisements. One flag, sixteen different subjects, no per-image tuning:

![cutout grid — 16 PD subjects, one CLI call each](docs/images/showcase-cutouts.png)

## Install

```bash
brew tap Arthur-Ficial/tap
brew install Arthur-Ficial/tap/bgbgone
```

Or from source (`make install` builds the release and installs into `/usr/local/bin`). Requires macOS 26+ and Command Line Tools. No Xcode needed.

## Quick start

```bash
bgbgone photo.jpg > cutout.png                              # to stdout
bgbgone photo.jpg -o cutout.png                             # to a file
bgbgone ~/photos/*.heic --out-dir ./cutouts                 # batch a folder
curl -L https://example.com/photo.jpg | bgbgone > out.png   # pipe in
cat photo.jpg | bgbgone --bg color:white > on-white.png     # pipe through
```

bgbgone refuses to write binary image bytes to a terminal — exactly like `curl`. Use `-o file`, `--out-dir dir`, or redirect to a file or pipe.

---

## Examples

Every image in this section is produced by `bash scripts/make-readme-examples.sh` from real bgbgone invocations against the documented [strict-PD Wikimedia fixtures](Tests/fixtures/LICENSES.md).

### Solid colour backgrounds

```bash
bgbgone in.jpg --bg color:white       -o out.png   # named
bgbgone in.jpg --bg color:black       -o out.png
bgbgone in.jpg --bg color:#0066cc     -o out.png   # hex
bgbgone in.jpg --bg color:rgb:0,200,0 -o out.png   # rgb triple
```

![--bg color: across three subjects, four colour syntaxes](docs/images/showcase-colors.png)

### Image backgrounds

```bash
bgbgone in.jpg --bg image:./bg.jpg                   -o out.png
bgbgone in.jpg --bg image:./bg.jpg --bg-fit cover    -o out.png   # default
bgbgone in.jpg --bg image:./bg.jpg --bg-fit contain  -o out.png
bgbgone in.jpg --bg image:./bg.jpg --bg-fit tile     -o out.png
bgbgone in.jpg --bg image:./bg.jpg --bg-fit center   -o out.png
```

Row 1 — same subject, every `--bg-fit` mode. Row 2 — same subject on two different PD backgrounds:

![--bg image:<path> with each --bg-fit mode and two distinct backgrounds](docs/images/showcase-image-bg.png)

Same subject (Mona Lisa) onto six different PD backgrounds, one invocation each:

![Mona Lisa — six PD backgrounds, one CLI call each](docs/images/mona-lisa-tour.png)

```bash
bgbgone mona-lisa.jpg --bg color:white                       -o studio.jpg
bgbgone mona-lisa.jpg --bg color:black                       -o dark.jpg
bgbgone mona-lisa.jpg --bg image:./hubble-ngc1300.jpg        -o galaxy.jpg
bgbgone mona-lisa.jpg --bg image:./nasa-aldrin-moon.jpg      -o moon.jpg
bgbgone mona-lisa.jpg --bg image:./hokusai-great-wave.jpg    -o wave.jpg
bgbgone mona-lisa.jpg --bg image:./mars-curiosity.jpg        -o mars.jpg
```

### Edge refinement

`--feather <px>` softens the matte edge, `--crop` tight-crops to the subject's bounding box, `--padding` adds breathing room, `--shadow` drops a shadow under the cutout, `--mask-only` emits the grayscale alpha matte:

![feather progression (0 → 16 px), --crop / --padding / --shadow / --mask-only](docs/images/showcase-edges.png)

```bash
bgbgone in.jpg --bg color:white --feather 8    -o soft.png
bgbgone in.jpg --crop                          -o tight.png
bgbgone in.jpg --crop --padding 10%            -o tight-padded.png
bgbgone in.jpg --bg color:white --shadow       -o dropshadow.png
bgbgone in.jpg --mask-only                     -o matte.png
```

Closer look at the matte itself — `--mask-only` writes the grayscale alpha; the compositor blends with that:

![input → grayscale matte → composite](docs/images/mask-breakdown.png)

Pixel-level zoom on the edge for `--feather 0` vs `--feather 8`:

![--feather close-up](docs/images/feather-zoom.png)

### Algorithm selection

```bash
bgbgone in.jpg --algo auto       # picks best for your macOS (default)
bgbgone in.jpg --algo vn-remove  # VNRemoveBackgroundRequest (macOS 15.1+)
bgbgone in.jpg --algo vn-mask    # VNGenerateForegroundInstanceMaskRequest (macOS 14+)
bgbgone in.jpg --algo person     # CIPersonSegmentation
bgbgone in.jpg --algo sky        # CISkySegmentation (subject = sky)
bgbgone in.jpg --algo saliency   # attention saliency (fallback)
```

Three subjects where the algorithms visibly diverge — a Mars rover with sky + ground, two people in a meadow, and a painted figure with no real sky:

![--algo across vn-remove / vn-mask / person / sky / saliency on three subjects](docs/images/showcase-algos.png)

`vn-remove` and `vn-mask` produce the same result on most subjects (they share the underlying foreground extractor). The `sky` row demonstrates the inversion case — `--algo sky` keeps the sky and discards everything else.

### Output formats

```bash
bgbgone in.jpg --to png                              # transparent PNG (default)
bgbgone in.jpg --to jpg --bg color:white --quality 92
bgbgone in.jpg --to heic
bgbgone in.jpg --to tiff
bgbgone in.jpg --to webp                             # if ImageIO supports it
bgbgone in.jpg --to avif                             # if ImageIO supports it
```

### Multi-instance

```bash
bgbgone team.jpg --multi --out-dir ./people/
# people/team-1.png, people/team-2.png, ...

bgbgone team.jpg --multi --instance-naming "subject_{n:02}.{ext}" --out-dir ./people/
# people/subject_01.png, people/subject_02.png, ...
```

The number of instances is decided by Vision. For tightly-grouped or touching subjects (e.g. an Apollo crew shoulder-to-shoulder) Vision returns one combined instance; for subjects with visible spatial gaps you get one file per subject.

### Structured output

```bash
bgbgone in.jpg --json -o out.png
```

```json
{"input":"in.jpg","output":"out.png","algo":"vn-remove","format":"png","width":1280,"height":960}
```

NDJSON streams through `jq`:

```bash
ls *.jpg | xargs -I{} bgbgone {} --ndjson --out-dir ./out/ \
  | jq -s 'group_by(.algo) | map({algo: .[0].algo, n: length})'
```

### Pipe into downstream AI

A clean cutout makes downstream classifiers, embedders, and OCR more accurate. With [auge](https://github.com/Arthur-Ficial/auge):

![pipeline: bgbgone → auge with real classify output](docs/images/showcase-pipeline.png)

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

### Product photography — every step

For each vintage product fixture: source → `--mask-only` matte → transparent cutout → composed onto a PD background. Same four-step pipeline, four different products:

![Products — source, mask-only, cutout, composed onto a PD background](docs/images/showcase-products.png)

```bash
bgbgone pierce-arrow-1909.jpg --mask-only                          -o matte.png
bgbgone pierce-arrow-1909.jpg                                      -o cutout.png
bgbgone pierce-arrow-1909.jpg --bg image:nasa-aldrin-moon.jpg      -o on-moon.png
```

Drop the new-background line and use `--bg color:white` instead and you have a white-bg product catalogue pipeline.

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

Chain with sibling tools — bg-remove, then classify or embed the cleaner cutout:

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
bgbgone v0.1.11 capability report
  OS:                  macOS 26.3.1
  Algorithms:
    vn-remove          available
    vn-mask            available
    person             available (CIPersonSegmentation, macOS 12+)
    sky                available (CISkySegmentation, macOS 12+)
    saliency           available (Vision, macOS 10.15+)
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
  --algo auto|vn-remove|vn-mask|person|sky|saliency   (default: auto)

MULTI-INSTANCE:
  --multi                               one file per detected instance
  --instance-naming "{base}-{n}.{ext}"  filename template (supports {n:NN})

OUTPUT:
  --to png|jpg|webp|heic|avif|tiff      output format (default: png)
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
```

## Architecture

```
CLI args                    main.swift
   │
   ▼                        ConfigParser (pure Swift, no Apple framework deps → testable)
Config
   │
   ▼                        BgBgOne pipeline
   ├─→ ForegroundMask       Algorithms/: VNRemove, VNMask, Person, Sky, Saliency
   ├─→ MaskPostProcess      feather, crop, --mask-only short-circuit
   ├─→ Compositor           SolidColor + ImageBg
   └─→ Output               ImageIO: PNG/JPG/WebP/HEIC/AVIF/TIFF
                            NetworkGuard hard-blocks http/https/ws/wss at runtime.
```

- `BgBgOneCore` library — pure Swift, no Vision dep, unit-testable.
- Main `bgbgone` target — Vision + Core Image integration.
- `bgbgone-tests` — pure-Swift test runner (no XCTest), same pattern as [apfel](https://github.com/Arthur-Ficial/apfel) and [auge](https://github.com/Arthur-Ficial/auge).

## Build & test

```bash
make install              # bump patch + build release + install to /usr/local/bin
make build                # bump patch + build release
make test                 # unit + integration
make test-unit            # Swift unit tests
make test-integration     # CLI e2e against strict-PD Wikimedia fixtures
make fixtures             # fetch the test fixtures (one-time)
```

`make test` runs 60 unit tests (argument parsing, colour parsing, instance-naming templating, network-scheme block list) and 48 integration tests (the built binary exercised end-to-end across all 16 fixture images and every flag combination).

### Test fixtures

The integration tests run against [16 squarely-public-domain Wikimedia images](Tests/fixtures/LICENSES.md): NASA spaceflight imagery (PD-USGov), 19th-century paintings and woodblock prints (PD-old by age, PD-Art), 19th/early-20th-century studio portraits (PD-old), and pre-1929 American advertisements for Singer sewing machines, the Underwood typewriter, the Edison phonograph, and the Pierce-Arrow automobile (PD-1929). No Creative Commons. Full provenance per fixture in `Tests/fixtures/LICENSES.md`.

Every example image in this README is regenerated by `scripts/make-readme-examples.sh` — the script is the audit trail for "every README image is real."

## Design

See [`docs/design.md`](docs/design.md) — CLI surface, algorithm selection, exit-code policy, framework version gating, and the UNIX-style contract every capability is held to.

## Privacy

- **No network.** `NetworkGuard.swift` registers a `URLProtocol` that intercepts any `http`, `https`, `ws`, or `wss` request inside the process and exits with code 3.
- **No telemetry.** No analytics, no crash reporting, no usage stats.
- **No API keys, no accounts, no subscriptions.**
- **Your images never leave your Mac.** Verifiable: try `bgbgone in.jpg` with the Wi-Fi off.

## License

MIT — see [LICENSE](LICENSE).
