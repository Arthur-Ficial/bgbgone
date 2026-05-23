# bgbgone

[![Version 1.0.0](https://img.shields.io/badge/version-1.0.0-blue)](https://github.com/Arthur-Ficial/bgbgone)
[![Website](https://img.shields.io/badge/website-bgbgone.franzai.com-1f6feb)](https://bgbgone.franzai.com/)
[![Swift 6.3+](https://img.shields.io/badge/Swift-6.3%2B-F05138?logo=swift&logoColor=white)](https://swift.org)
[![macOS 26+](https://img.shields.io/badge/macOS-26%2B-000000?logo=apple&logoColor=white)](https://developer.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![100% On-Device](https://img.shields.io/badge/privacy-100%25%20on--device-green)](https://developer.apple.com/documentation/vision)
[![100% Scriptable](https://img.shields.io/badge/scriptable-100%25-green)](#why)

**Official site: [bgbgone.franzai.com](https://bgbgone.franzai.com/)**

## Background, be gone!

One shell command. Any image. Transparent cutout in 86 milliseconds. 100% on your Mac. 100% scriptable. Others sell this as a subscription, but free and open source is just cooler. A 3 MB binary you `brew install` once and own forever.

![bgbgone hero](docs/images/hero.png)

## Filter showcase

Five real one-shot transforms produced by `bgbgone --filter` against the strict-CC0 fixtures in `Tests/fixtures/showcase/`. Run [`scripts/make-filter-showcase.sh`](scripts/make-filter-showcase.sh) to regenerate every asset below against the freshly-installed binary.

### 1. Colour-pop — black-and-white background, colour subject

```bash
bgbgone corgi.jpg --bg color:white --filter "bg:grayscale" -o corgi-colourpop.jpg
```

| Before | After |
|---|---|
| ![corgi original](docs/images/showcase/01-corgi-before.jpg) | ![corgi colour-pop](docs/images/showcase/01-corgi-colourpop.jpg) |

The subject keeps every shade of fawn fur; the white backdrop turns grey. Powered by `CIColorControls` with saturation 0 on the `bg` layer.

### 2. Portrait mode — silky background blur, sharp subject

```bash
bgbgone yoga.jpg --bg color:white --filter "bg:blur=20" -o yoga-portrait.jpg
```

| Before | After |
|---|---|
| ![yoga original](docs/images/showcase/02-yoga-before.jpg) | ![yoga portrait mode](docs/images/showcase/02-yoga-portraitmode.jpg) |

Phone-camera portrait mode on any subject. `CIGaussianBlur` runs on the background plate only; the foreground stays pin-sharp.

### 3. Sticker style — coloured outline + drop shadow on transparent

```bash
bgbgone corgi.jpg \
  --filter "fg:outline=color=#fff:width=4,shadow=blur=12:offset=4,4:opacity=0.5:color=#000" \
  -o corgi-sticker.png
```

| Cutout | Sticker |
|---|---|
| ![corgi cutout](docs/images/showcase/03-corgi-cutout.png) | ![corgi sticker](docs/images/showcase/03-corgi-sticker.png) |

`CIMorphologyMaximum` dilates the matte for the white halo, `CIGaussianBlur` + `CIAffineTransform` produces the drop shadow. The chain order matters: outline first, then shadow under it.

### 4. Vintage finish — sepia tone + vignette

```bash
bgbgone pipeman.jpg --bg color:white --filter "sepia=0.7,vignette=1:1.2" -o pipeman-vintage.jpg
```

| Before | After |
|---|---|
| ![pipe-man original](docs/images/showcase/04-pipeman-before.jpg) | ![pipe-man vintage](docs/images/showcase/04-pipeman-vintage.jpg) |

`CISepiaTone` at 70% + `CIVignette`. Composite-only chain (no `fg:`/`bg:` prefix needed) operates on the final compositied frame.

### 5. Dramatic composite — subject on the Matterhorn at golden hour

```bash
bgbgone yoga.jpg \
  --bg "image:./Matterhorn_sunset.jpg" \
  --filter "bg:adjust=brightness=-0.15:saturation=0.8; fg:adjust=saturation=1.2" \
  -o yoga-matterhorn.jpg
```

| Plain composite | Colour-graded |
|---|---|
| ![yoga on Matterhorn](docs/images/showcase/05-yoga-matterhorn-before.jpg) | ![yoga on Matterhorn graded](docs/images/showcase/05-yoga-matterhorn-graded.jpg) |

Background gets a moody darken + desaturate, foreground gets a saturation boost. Two stages in one chain (`;`) — left-to-right evaluation, independent layer scopes.

### Showcase image credits

All showcase fixtures are CC0 or Franz Enzenhofer's own CC BY 4.0 work. Sidecar JSONs travel with every fixture (`Tests/fixtures/showcase/*.json`).

| Fixture | Subject | Licence | Source |
|---|---|---|---|
| `Fawn_and_white_Welsh_Corgi_puppy_...jpg` | Huoadg5888 (Pixabay) | CC0 / Public Domain | [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Fawn_and_white_Welsh_Corgi_puppy_standing_on_rear_legs_and_sticking_out_the_tongue.jpg) |
| `franz-yoga.jpg` | Franz Enzenhofer | **CC BY 4.0** | own work |
| `Bearded_man_smoking_pipe-3013924.jpg` | Pexels contributor | CC0 / Public Domain | [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Bearded_man_smoking_pipe-3013924.jpg) |
| `bg/Matterhorn_sunset_2016__Unsplash_.jpg` | Eberhard Grossgasteiger (Unsplash) | CC0 / Public Domain | [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Matterhorn_sunset_2016_(Unsplash).jpg) |

Full per-filter docs in [`docs/filters/`](docs/filters/). The 49-filter catalogue: [`docs/filters/README.md`](docs/filters/README.md).

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
bgbgone --server                                  # local HTTP API
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

### Local HTTP API

```bash
bgbgone --server                                             # 127.0.0.1:8787, no auth, localhost only
bgbgone --server --port 9000                                 # custom port
bgbgone --server --token-auto                                # one-shot Bearer token, printed on startup
bgbgone --server --token "$(openssl rand -hex 16)"           # explicit token
bgbgone --server --cors --allowed-origins http://localhost:3000   # CORS for a trusted browser app
bgbgone --server --host 0.0.0.0 --token-auto --public-health      # LAN-exposed, /health stays public
bgbgone --server --max-body-mb 64                            # raise body limit (default 32 MiB)
```

```bash
curl -X POST http://127.0.0.1:8787/v1.0/bgbgone \
    -F image_file=@photo.jpg \
    -F format=png \
    -o cutout.png
```

The server is still 100% on-device: it accepts uploaded image bytes, runs the same Vision/Core Image pipeline as the CLI, and never fetches remote image URLs. It binds to `127.0.0.1:8787` by default, supports optional Bearer token auth (or `X-API-Key`), CORS for trusted local browser apps, an additive origin allowlist, JSON / multipart / urlencoded request bodies (also `image_file_b64`), ZIP output, `X-Width` / `X-Height` / `X-Foreground-*` / `X-Type` metadata headers, and a request body limit. Full details: [`docs/server/`](docs/server/).

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

`--feather <px>` softens the matte edge. `--crop` tight-crops to the subject's bounding box. `--padding` and `--crop-margin` add breathing room. `--roi` limits detection to a region. `--scale` and `--position` place the subject on the canvas. `--shadow` and `--shadow-type drop` add a shadow under the cutout. `--semitransparency false` hardens the matte so soft edges become opaque. `--mask-only` emits the grayscale alpha matte.

![feather progression (0 to 16 px), --crop, --padding, --shadow, --mask-only](docs/images/showcase-edges.png)

```bash
bgbgone in.jpg --bg color:white --feather 8           -o soft.png
bgbgone in.jpg --threshold 0.55                       -o crisper.png
bgbgone in.jpg --crop                                 -o tight.png
bgbgone in.jpg --crop --padding 10%                   -o tight-padded.png
bgbgone in.jpg --crop --crop-margin "5% 10%"          -o api-padded.png
bgbgone in.jpg --crop --crop-margin "5% 10% 15% 20%"  -o four-sided.png
bgbgone in.jpg --roi "0% 0% 100% 80%"                 -o top-region.png
bgbgone in.jpg --scale 75% --position center          -o centered.png
bgbgone in.jpg --scale 50% --position "25% 75%"       -o lower-left.png
bgbgone in.jpg --bg color:white --shadow              -o dropshadow.png
bgbgone in.jpg --shadow-type drop --shadow-opacity 25 -o soft-shadow.png
bgbgone in.jpg --shadow-type none                     -o no-shadow.png
bgbgone in.jpg --semitransparency false               -o hard-edge.png
bgbgone in.jpg --mask-only                            -o matte.png
bgbgone in.jpg --channels alpha                       -o matte.png   # same as --mask-only
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

### Subject hints

`--type` is the friendlier sibling of `--algo`. It accepts the same subject-hint vocabulary as the local HTTP API, then resolves to the best on-device algorithm:

```bash
bgbgone portrait.jpg     --type person          -o cutout.png
bgbgone bottle.jpg       --type product         -o cutout.png
bgbgone sedan.jpg        --type car             -o cutout.png
bgbgone elephant.jpg     --type animal          -o cutout.png
bgbgone logo.png         --type graphic         -o cutout.png
bgbgone bicycle.jpg      --type transportation  -o cutout.png
bgbgone busy-scene.jpg   --type saliency        -o cutout.png   # explicit objectness saliency
bgbgone any.jpg          --type vn-mask         -o cutout.png   # explicit foreground-instance mask
```

### Output formats

```bash
bgbgone in.jpg --to png                              # transparent PNG (default)
bgbgone in.jpg --to jpg --quality 92                 # white bg unless --bg is set
bgbgone in.jpg --to zip                              # color.jpg + alpha.png package
bgbgone in.jpg -o out.jpg                            # extension infers JPEG
bgbgone in.jpg -o out.heic                           # extension infers HEIC
bgbgone in.jpg --to heic
bgbgone in.jpg --to avif
bgbgone in.jpg --to tiff
bgbgone in.jpg --format png                          # --format is an alias of --to
```

### Output size cap

`--size` caps the output by megapixels so a 12 MP source can land on the web in one call. PNG outputs are additionally clamped to 10 MP (alpha cost) just like the local API.

```bash
bgbgone giant.jpg --size preview --to jpg -o thumb.jpg    # 0.25 MP cap
bgbgone giant.jpg --size full                  -o full.png   # 25 MP cap (10 MP for PNG)
bgbgone giant.jpg --size 50MP --to jpg          -o huge.jpg   # 50 MP cap
bgbgone giant.jpg --size auto  --to jpg         -o auto.jpg   # same cap as full
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

### Local HTTP API

When pipes aren't an option (browser apps, drag-and-drop demos, Postman collections), run the same pipeline behind a local HTTP server. It's still 100% on-device — `NetworkGuard` hard-blocks outbound traffic inside the process.

```bash
bgbgone --server                                              # 127.0.0.1:8787
bgbgone --server --port 9000                                  # custom port
bgbgone --server --token "$(openssl rand -hex 16)"            # require Bearer / X-API-Key
bgbgone --server --token-auto                                 # print one-shot token on startup
bgbgone --server --cors --allowed-origins http://localhost:3000  # CORS for a trusted SPA
bgbgone --server --host 0.0.0.0 --token-auto --public-health  # LAN-exposed, /health stays public
bgbgone --server --max-body-mb 64                             # raise body limit (default 32 MiB)
bgbgone --server --no-origin-check                            # disable browser origin filtering
bgbgone --server --footgun                                    # wildcard CORS + no origin check (demos only)
```

Endpoints:

```bash
curl http://127.0.0.1:8787/health                                # liveness JSON
curl http://127.0.0.1:8787/v1.0/account                          # local account shape, zero credits

curl -X POST http://127.0.0.1:8787/v1.0/bgbgone \
    -F image_file=@photo.jpg -F format=png -o cutout.png         # multipart, PNG

curl -X POST http://127.0.0.1:8787/v1.0/bgbgone \
    -F image_file=@photo.jpg -F format=jpg -F bg_color=ffffff \
    -o on-white.jpg                                              # JPEG on white

curl -X POST http://127.0.0.1:8787/v1.0/bgbgone \
    -F image_file=@photo.jpg -F channels=alpha -o matte.png      # mask-only

curl -X POST http://127.0.0.1:8787/v1.0/bgbgone \
    -F image_file=@photo.jpg -F format=zip -o result.zip         # color.jpg + alpha.png

curl -X POST http://127.0.0.1:8787/v1.0/bgbgone \
    -H "Accept: application/json" \
    -F image_file=@photo.jpg                                     # JSON-wrapped base64 PNG

curl -X POST http://127.0.0.1:8787/v1.0/bgbgone \
    -H "Authorization: Bearer $TOKEN" \
    -F image_file=@photo.jpg -F type=person -F type_level=2 \
    -o portrait.png                                              # token auth + subject hint

curl -X POST http://127.0.0.1:8787/v1.0/bgbgone \
    -H "Content-Type: application/json" \
    -d '{"image_file_b64":"<base64>","format":"jpg","bg_color":"#0066cc","scale":"60%","position":"25% 75%"}'
```

Successful image responses include `X-Width`, `X-Height`, `X-Credits-Charged: 0`, `X-Foreground-Top`, `X-Foreground-Left`, `X-Foreground-Width`, `X-Foreground-Height`, and (unless `type_level=none`) `X-Type`. Remote `image_url` / `bg_image_url` inputs respond `501 NOT IMPLEMENTABLE` so the no-network promise holds. Full wire contract and security matrix in [`docs/server/`](docs/server/).

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

Run a token-protected local server for a browser SPA on `localhost:3000`:

```bash
TOKEN="$(openssl rand -hex 16)"
bgbgone --server --token "$TOKEN" --cors --allowed-origins http://localhost:3000 &
# in the SPA:
fetch("http://127.0.0.1:8787/v1.0/bgbgone", {
    method: "POST",
    headers: { Authorization: "Bearer " + token },
    body: formData
});
```

Drop a "remove background" hot folder onto your Mac with a one-liner watcher:

```bash
fswatch -0 ~/Drop | while IFS= read -r -d '' f; do
    bgbgone "$f" --bg color:white --to jpg --quality 92 \
        --out-dir ~/Drop/out/ --json --quiet
done
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
bgbgone v0.1.37 capability report
  OS:                  macOS 26.3.1
  Algorithms:
    vn-mask            available (foreground-instance mask, macOS 14+)
    person             available (Vision person segmentation, macOS 12+)
    saliency           available (Vision objectness saliency, macOS 10.15+)
  Output formats:      png, jpg, zip, heic, avif, tiff
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
  --roi "x1 y1 x2 y2"                   region of interest, px or %
  --scale <10%..100%|original>          scale subject on the canvas
  --position <center|x% y%|original>    place scaled subject on canvas
  --semitransparency true|false         keep or harden semi-transparent matte pixels
  --shadow                              drop shadow under cutout
  --shadow-type auto|drop|3D|car|none   shadow compatibility selector
  --shadow-opacity <0..100|auto>        shadow darkness

ALGORITHM:
  --algo auto|vn-mask|person|saliency   (default: auto)
  --type auto|person|product|car|animal|graphic|transportation

MULTI-INSTANCE:
  --multi                               one file per detected instance (file input only)
  --instance-naming "{base}-{n}.{ext}"  filename template (supports {n:NN})

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
   ├─→ MaskPostProcess      threshold, feather, ROI, crop, padding, --mask-only
   ├─→ Compositor           SolidColor + ImageBg
   └─→ Output               ImageIO: PNG/JPG/HEIC/AVIF/TIFF + ZIP package
HTTP server ───────────────→ same pipeline, multipart/JSON/form uploads, JSON/base64 option
                            NetworkGuard hard-blocks outbound http/https/ws/wss at runtime.
```

- `BgBgOneCore` library: pure Swift, no Vision dep, unit-testable.
- Main `bgbgone` target: Vision + Core Image integration.
- `bgbgone-tests`: pure-Swift test runner (no XCTest), same pattern as [apfel](https://github.com/Arthur-Ficial/apfel) and [auge](https://github.com/Arthur-Ficial/auge).

## Performance

```bash
make test-performance-100
```

100 fixture-backed inputs, five batch processes, 100 outputs verified per run. Release-gate performance is measured with:

```bash
bash Tests/performance/run-100.sh .build/release/bgbgone
```

Average over 5 release-binary runs: **100 images in 1.223 s, 81.74 images/s, 12.2 ms/image** with 95,487,542 output bytes verified per run. On-device, no network, no GPU contention with another process.

### Optional sustained-throughput tests (1k / 10k)

```bash
make test-performance-1000    # 10 x 100  = 1,000  image operations
make test-performance-10000   # 100 x 100 = 10,000 image operations
```

Both replay the same 100-image batch the release-gate exercises, but call the binary **N times in a row**. **Not part of `make release`** — opt-in. Models a heavy user who runs the same batch over and over throughout a day. Every invocation must produce identical output bytes (determinism check) and the matching README line below is re-written on every run, so repeated invocations always show the current measurement.

```bash
bash Tests/performance/run-sustained.sh .build/release/bgbgone 10    # 1k
bash Tests/performance/run-sustained.sh .build/release/bgbgone 100   # 10k
```

Average over 10 release-binary invocations of 100: **1000 image operations in 12.174 s, 82.14 images/s, 12.2 ms/image** with 95,487,542 output bytes verified per invocation. On-device, no network, no GPU contention with another process.

Average over 100 release-binary invocations of 100: **10000 image operations in 124.668 s, 80.21 images/s, 12.5 ms/image** with 95,487,542 output bytes verified per invocation. On-device, no network, no GPU contention with another process.

## Build & test

```bash
make install              # bump patch + build release + install to /usr/local/bin
make build                # bump patch + build release
make test                 # unit + integration
make test-unit            # Swift unit tests
make test-integration     # CLI e2e against strict-PD Wikimedia fixtures
make test-performance-100   # 100-image release-gate performance scenario
make test-performance-1000  # OPTIONAL 10 x 100  = 1,000  sustained ops
make test-performance-10000 # OPTIONAL 100 x 100 = 10,000 sustained ops
make fixtures             # fetch the test fixtures (one-time)
```

### Test fixtures

The integration tests run against [16 squarely-public-domain Wikimedia images](Tests/fixtures/LICENSES.md): NASA spaceflight imagery (PD-USGov), 19th-century paintings and woodblock prints (PD-old, PD-Art), 19th and early-20th-century studio portraits (PD-old), and pre-1929 American advertisements for Singer sewing machines, the Underwood typewriter, the Edison phonograph, and the Pierce-Arrow automobile (PD-1929). No Creative Commons. Full provenance per fixture in `Tests/fixtures/LICENSES.md`.

Every example image in this README is regenerated by `scripts/make-readme-examples.sh` against a freshly-installed binary on every release. The script is the audit trail for "every README image is real."

## Design

See [`docs/design.md`](docs/design.md) for the CLI surface, algorithm selection, exit-code policy, framework version gating, and the UNIX-style contract every capability is held to.

## Contributing

See [`DEVELOPMENT.md`](DEVELOPMENT.md) for the working agreement - hard rules, TDD procedure, UNIX checklist, performance budget, dependency policy, commit conventions, and release gate. Every commit on `main` is held to it.

## Privacy

- **No network.** `NetworkGuard.swift` registers a `URLProtocol` that intercepts any `http`, `https`, `ws`, or `wss` request inside the process and exits with code 3.
- **No telemetry.** No analytics, no crash reporting, no usage stats.
- **No API keys, no accounts, no subscriptions.**
- **Your images never leave your Mac.** Verifiable: run `bgbgone in.jpg` with Wi-Fi off.

## License

MIT. See [LICENSE](LICENSE).
