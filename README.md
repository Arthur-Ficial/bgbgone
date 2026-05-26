# bgbgone

[![Version 1.1.23](https://img.shields.io/badge/version-1.1.23-blue)](https://github.com/Arthur-Ficial/bgbgone)
[![Swift 6.3+](https://img.shields.io/badge/Swift-6.3%2B-F05138?logo=swift&logoColor=white)](https://swift.org)
[![macOS 26+](https://img.shields.io/badge/macOS-26%2B-000000?logo=apple&logoColor=white)](https://developer.apple.com/macos/)
[![100% on-device](https://img.shields.io/badge/privacy-100%25%20on--device-green)](https://developer.apple.com/documentation/vision)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**The UNIX-style background remover for macOS. Image in, transformed image out. Apple Vision masks + Core Image. Zero dependencies. 100% on-device. 100% scriptable.**

![bgbgone hero](docs/images/hero.png)

## Install

```bash
brew install Arthur-Ficial/tap/bgbgone
```

Or from source: `make install` (writes to `/usr/local/bin`). macOS 26+, no Xcode needed, ~3 MB binary, zero deps.

## Quickstart

Transparent cutout — refuses a TTY, so pipe or `-o`.

```bash
bgbgone red-panda.jpg -o red-panda-cutout.png
```

![transparent cutout grid](docs/images/showcase-cutouts.png)

Solid colour background.

```bash
bgbgone red-panda.jpg --bg color:white -o red-panda-on-white.jpg
```

![colour backgrounds](docs/images/showcase-colors.png)

Image background with fit modes (`cover` / `contain` / `center` / `tile`).

```bash
bgbgone yoga.jpg --bg image:matterhorn-sunset.jpg --bg-fit cover -o yoga-on-matterhorn.jpg
```

![image backgrounds (fit modes)](docs/images/showcase-image-bg.png)

## Filter chain — 49 filters, one grammar

`--filter "<layer>:<name>[=args][,<name>...]; <layer>:..."`
Layers are `bg` / `fg` / `all` / `mask` / `composite`. See [docs/filters/](docs/filters/README.md) for the full catalogue with paired image per filter.

### Colour-pop — background goes B&W, subject keeps its colour

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:grayscale" -o panda-colourpop.jpg
```

![colour-pop on red panda](docs/images/showcase/01-panda-colourpop.jpg)

### Portrait mode — background gets a silky Gaussian blur

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:blur=60" -o panda-portrait.jpg
```

![portrait-mode blur on red panda](docs/images/showcase/02-panda-portraitmode.jpg)

### Die-cut sticker — drop shadow + thick white outline

```bash
bgbgone corgi-puppy.jpg --bg color:#1a2233 \
  --filter "fg:shadow=blur=40:offset=22,22:opacity=0.7:color=#000,outline=color=#fff:width=30" \
  -o corgi-sticker.jpg
```

![die-cut sticker on corgi](docs/images/showcase/03-corgi-sticker.jpg)

### Vintage backdrop — `--type person` isolates the subject, bg goes sepia

```bash
bgbgone woman-singer.jpg --type person \
  --filter "bg:sepia=1.0,adjust=brightness=-0.15:saturation=0.45; composite:vignette=1.8:1.1" \
  -o woman-singer-vintage.jpg
```

![vintage backdrop on woman-singer](docs/images/showcase/04-woman-singer-vintage.jpg)

## Edge refinement — `mask:feather`

Soften the matte edge by N pixels. 0 = razor edge; 32 = obvious halo.

```bash
bgbgone corgi-puppy.jpg --filter "mask:feather=16" --bg color:#1a2233 -o corgi-feather16.jpg
```

![feather 0 vs 16 zoom](docs/images/feather-zoom.png)

## Server mode — same surface over HTTP

```bash
bgbgone --server --host 127.0.0.1 --port 8088
```

POSTs to `/bgbgone` accept the same options as the CLI (`bg`, `filter`, `format`, `type`, …) via multipart, JSON, or form. See [docs/server/README.md](docs/server/README.md).

## Pipelines

stdin → stdout: pipe-friendly, refuses a TTY for safety.

```bash
cat red-panda.jpg | bgbgone > red-panda-cutout.png
```

![stdin-to-stdout cutout](docs/images/before-after.png)

Batch directory with parallel Vision: every input gets its own output.

```bash
mkdir -p ./out/
bgbgone red-panda.jpg corgi-puppy.jpg yoga.jpg --out-dir ./out/
```

![algorithm comparison across fixtures](docs/images/showcase-algos.png)

## Output formats + algorithms

`--format png|jpg|heic|avif|tiff|zip` and `--type auto|person|product|car|animal|graphic|transportation|saliency`. See [`bgbgone --help`](docs/design.md) and [`bgbgone --check`](docs/design.md).

```bash
bgbgone red-panda.jpg --type animal --format heic -o red-panda.heic
```

![pipeline showcase across types](docs/images/showcase-pipeline.png)

## Architecture

```
CLI args  →  ConfigParser (pure)  →  BgBgOne pipeline
                                       ├─ Algorithms/  (Vision mask: vn-mask, person, saliency)
                                       ├─ FilterPipeline (49 Core Image filters)
                                       ├─ Compositor   (mask + bg)
                                       └─ Output       (PNG / JPG / WebP / HEIC / AVIF / TIFF / ZIP)
                                              ↑
                                          NetworkGuard hard-blocks all sockets at runtime
```

CLI and `--server` resolve to the same `Config` and run the same pipeline — see [docs/design.md](docs/design.md).

## Exit codes

| code | meaning |
|------|---------|
| `0` | success |
| `1` | user error (bad input, refusing TTY) |
| `2` | parser error / no foreground subject found |
| `3` | framework error (Vision unavailable) |

## Development

Working agreement: [DEVELOPMENT.md](DEVELOPMENT.md). Per-AI-session rules: [CLAUDE.md](CLAUDE.md). Build + test + release loop:

```bash
make test       # lint-fixtures + lint-readme + lint-contract + unit + integration + doc-block harness
make install    # bump patch + build release + install to /usr/local/bin
make release    # full release gate; regenerates every shipped image
make deploy     # release + tag + push + GitHub release + Homebrew tap bump
```

Every fenced ```bash block in this README and in every doc under [`docs/`](docs/) is executed by `scripts/test-doc-blocks.sh` against the installed binary on every `make test`. A block that fails the test is a build break.

## Images + attribution

All 26 test fixtures are public-domain or CC0, with one CC BY 4.0 own-work portrait. One row per file in [Tests/fixtures/LICENSES.md](Tests/fixtures/LICENSES.md), enforced 1:1 by [`scripts/lint-fixtures.sh`](scripts/lint-fixtures.sh).

## License

MIT. See [LICENSE](LICENSE).
