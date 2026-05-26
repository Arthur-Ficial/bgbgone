# bgbgone

[![Version 1.2.23](https://img.shields.io/badge/version-1.2.23-blue)](https://github.com/Arthur-Ficial/bgbgone)
[![Swift 6.3+](https://img.shields.io/badge/Swift-6.3%2B-F05138?logo=swift&logoColor=white)](https://swift.org)
[![macOS 26+](https://img.shields.io/badge/macOS-26%2B-000000?logo=apple&logoColor=white)](https://developer.apple.com/macos/)
[![100% on-device](https://img.shields.io/badge/privacy-100%25%20on--device-green)](https://developer.apple.com/documentation/vision)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**The UNIX-style background remover for macOS. Image in, transformed image out. Apple Vision masks + Core Image. Zero dependencies. 100% on-device. 100% scriptable.**

![bgbgone hero](docs/images/hero.png)

## Contents

- [Install](#install)
- [Inputs used in this README](#inputs-used-in-this-readme)
- **Output modes — red-panda**
  - [Transparent cutout](#transparent-cutout-on-red-panda)
  - [Alpha matte (`--channels alpha`)](#alpha-matte-on-red-panda----channels-alpha)
  - [Solid-colour background](#solid-colour-background-on-red-panda)
  - [Universe-photo background](#universe-photo-background-on-red-panda--red-panda-in-space)
- **Filter chain — single-fixture demos**
  - [Colour-pop on red-panda](#colour-pop-on-red-panda--bg-goes-bw-subject-keeps-its-colour)
  - [Portrait mode on red-panda](#portrait-mode-on-red-panda--silky-bg-blur)
  - [Die-cut sticker on corgi-puppy](#die-cut-sticker-on-corgi-puppy--cropped-to-subject-transparent-hard-white-border)
  - [Motion-radial backdrop on woman-singer](#motion-radial-backdrop-on-woman-singer--bgzoom-blur---type-person)
  - [Edge refinement on corgi-puppy](#edge-refinement-on-corgi-puppy--maskfeather-3-values-last-extreme)
- [Pipelines on red-panda](#pipelines-on-red-panda--compose-with-sibling-apple-framework-clis)
- **Filter catalogue**
  - [Filter overview + index (49 filters)](docs/filters/README.md)
  - [Filter chain grammar](#filter-chain-grammar)
- [Server mode](#server-mode) — full walkthrough: [`SERVER-README.md`](SERVER-README.md)
- [Exit codes](#exit-codes)
- [Architecture](#architecture)
- [Development](#development)
- [Images + attribution](#images--attribution)
- [License](#license)

## Install

Run `brew install Arthur-Ficial/tap/bgbgone` (macOS 26+, ~3 MB binary, no Xcode needed). From source: `make install` writes to `/usr/local/bin`.

## Industry-scale load test

Real measurements from `make load-test-table` against the installed release binary on this machine. On-device, no network, single bgbgone process per batch of 100 inputs. Inputs are strict-PD Wikimedia fixtures (JPG, 95 KB - 665 KB each) cycled into batches. Output bytes are verified identical across every invocation, so timings reflect real work — not caching, not no-ops.

<!-- LOAD-TEST-TABLE-START -->
| Images | Total time | Per image | Throughput |
|-------:|-----------:|----------:|-----------:|
| 100 | 2.75 s | 27.5 ms | 36.30 img/s |
| 1 000 | 28.82 s | 28.8 ms | 34.69 img/s |
| 10 000 | 4 min 54 s | 29.4 ms | 34.01 img/s |
<!-- LOAD-TEST-TABLE-END -->

Reproduce: `make load-test-table`. Or per scale: `make perf-100`, `make perf-1000`, `make perf-10000`.

## Inputs used in this README

Three originals drive every example below. Each is shown once here; later sections reference the same fixtures without repeating the big preview.

| `red-panda.jpg` | `corgi-puppy.jpg` | `woman-singer.jpg` |
|---|---|---|
| ![red-panda original](docs/images/showcase/01-panda-before.jpg) | ![corgi-puppy original](docs/images/showcase/03-corgi-before.jpg) | ![woman-singer original](docs/images/showcase/04-woman-singer-before.jpg) |

## Transparent cutout on red-panda

The default: bgbgone removes the background and emits a PNG with alpha. Transparent areas render as the GitHub theme background (or — here — as a checkerboard so you can see the alpha).

```bash
bgbgone red-panda.jpg -o red-panda-cutout.png
```

![red-panda transparent cutout (checkerboard shows alpha)](docs/images/red-panda/cutout.png)

## Alpha matte on red-panda — `--channels alpha`

Emit the alpha mask itself as a grayscale silhouette. Useful for downstream compositing pipelines that want the matte instead of the colour cutout.

```bash
bgbgone red-panda.jpg --channels alpha -o red-panda-matte.png
```

![red-panda alpha matte — silhouette as grayscale](docs/images/red-panda/matte.png)

## Solid-colour background on red-panda

Drop the cutout onto a flat colour. JPEG output works because alpha is composited away.

```bash
bgbgone red-panda.jpg --bg color:#1a2233 -o red-panda-on-navy.jpg
```

![red-panda on a solid navy background](docs/images/red-panda/on-navy.jpg)

## Universe-photo background on red-panda — red panda in space

Use any image as the background. Here the [Flaming Star Nebula (Chuck Ayoub, CC0)](Tests/fixtures/nebula-flaming-star.png) — same fixture used in `Tests/fixtures/`.

```bash
bgbgone red-panda.jpg --bg "image:nebula-flaming-star.png" -o red-panda-in-space.jpg
```

![red-panda composited onto the Flaming Star Nebula](docs/images/red-panda/in-space.jpg)

## Colour-pop on red-panda — bg goes B&W, subject keeps its colour

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:grayscale" -o red-panda-colourpop.jpg
```

![red-panda colour-pop](docs/images/showcase/01-panda-colourpop.jpg)

## Portrait mode on red-panda — silky bg blur

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:blur=60" -o red-panda-portrait.jpg
```

![red-panda portrait-mode blur](docs/images/showcase/02-panda-portraitmode.jpg)

## Die-cut sticker on corgi-puppy — cropped to subject, transparent, hard white border

A real die-cut sticker is the subject itself with a thick hard white border, sitting on a transparent surface. Two steps: cutout-and-crop first, then add the outline on the transparent cutout. (Adding the outline directly on the raw photo keeps the original background visible outside the outline.)

```bash
bgbgone corgi-puppy.jpg --crop --crop-margin "8%" -o corgi-cutout.png
bgbgone corgi-cutout.png --filter "fg:outline=color=#fff:width=30" -o corgi-sticker.png
```

![corgi-puppy die-cut sticker — hard solid white border, transparent background (checkerboard shows alpha)](docs/images/showcase/03-corgi-sticker.png)

## Motion-radial backdrop on woman-singer — `bg:zoom-blur`, `--type person`

```bash
bgbgone woman-singer.jpg --type person \
  --bg "image:woman-singer.jpg" \
  --filter "bg:zoom-blur=center=0.5,0.45:amount=60" \
  -o woman-singer-zoom-blur.jpg
```

![woman-singer zoom-blur backdrop — bg radiates outward, subject razor-sharp](docs/images/showcase/04-woman-singer-zoom-blur.jpg)

## Edge refinement on corgi-puppy — `mask:feather` (3 values, last extreme)

`feather=N` softens the matte edge by N pixels. The close-up below shows three values on the same fixture, centred on the chest where fur meets the blurred background: default hard edge, `mask:feather=24` (soft glow), and `mask:feather=80` (extreme diffuse halo).

```bash
bgbgone corgi-puppy.jpg                                -o corgi-f0.png   # razor edge
bgbgone corgi-puppy.jpg --filter "mask:feather=24"     -o corgi-f24.png  # soft glow
bgbgone corgi-puppy.jpg --filter "mask:feather=80"     -o corgi-f80.png  # extreme
```

![corgi-puppy mask:feather at 0, 24, and 80 — hard edge → soft glow → extreme diffuse halo](docs/images/feather-zoom.png)

## Pipelines on red-panda — compose with sibling Apple-framework CLIs

```bash
bgbgone red-panda.jpg -o red-panda-cutout.png && auge --classify red-panda-cutout.png
```

![bgbgone piped into auge --classify](docs/images/showcase-pipeline.png)

## Filter chain grammar

`--filter "<layer>:<name>[=args][,<name>...]; <layer>:..."`. Layers are `bg` / `fg` / `all` / `mask` / `composite`.

- **Filter overview + index (49 filters):** [`docs/filters/README.md`](docs/filters/README.md) — grouped by layer set, every row links to its per-filter doc with paired before/after image.
- **Machine-readable catalogue:** `bgbgone --filters-list --json` emits a stable JSON array with `name`, `layers`, `signature`, `doc`, `producesAlpha`, `positional`, `keyed`, `examples`.
- **Per-filter human help:** `bgbgone --help filter=<name>`.

## Server mode

`bgbgone --server` exposes the same Config + pipeline over local HTTP. Every flag has an HTTP twin with byte-identical output, verified in [`Tests/integration/run-server-parity.sh`](Tests/integration/run-server-parity.sh) (19 cases, all green).

One example, same colour-pop as the section above:

```bash
bgbgone --server --host 127.0.0.1 --port 8787 &
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "format=jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=bg:grayscale" \
  -o red-panda-colourpop.jpg
```

![red-panda colour-pop via HTTP — byte-identical to the CLI version above](docs/images/showcase/01-panda-colourpop.jpg)

**Full server walkthrough — every example in this README mirrored as curl:** [`SERVER-README.md`](SERVER-README.md). Wire contract: [`docs/server/README.md`](docs/server/README.md). Security matrix: [`docs/server/security.md`](docs/server/security.md).

## Exit codes

| code | meaning |
|------|---------|
| `0` | success |
| `1` | user error (bad input, refusing TTY) |
| `2` | parser error / no foreground subject found |
| `3` | framework error (Vision unavailable) |

## Architecture

`CLI args` → `ConfigParser` (pure Swift) → `BgBgOne` pipeline → `Algorithms/` (Vision: vn-mask / person / saliency) + `FilterPipeline` (49 Core Image filters) + `Compositor` (mask + bg) → `Output` (PNG / JPG / HEIC / AVIF / TIFF / ZIP). `NetworkGuard` hard-blocks all sockets at runtime. CLI and `--server` resolve to the same `Config` and run the same pipeline. Details: [docs/design.md](docs/design.md).

## Development

Working agreement: [DEVELOPMENT.md](DEVELOPMENT.md). Per-AI-session rules: [CLAUDE.md](CLAUDE.md).

- `make test` — every lint (`lint-fixtures`, `lint-readme`, `lint-contract`, `lint-docs`, `lint-doc-images`, `lint-block-pairing`) + unit + integration + doc-block harness
- `make install` — bump patch + build release + install to `/usr/local/bin`
- `make release` — full release gate; regenerates every shipped image asset
- `make deploy` — release + tag + push + GitHub release + Homebrew tap bump

Every fenced bash block in this README and in every doc under `docs/` is executed against the installed binary by `scripts/test-doc-blocks.sh` on every `make test`. Every image link is checked by `scripts/lint-doc-images.sh`. Every bgbgone visual-demo block must be paired with an image (enforced by `scripts/lint-block-pairing.sh`).

## Images + attribution

All 26 test fixtures are public-domain or CC0, with one CC BY 4.0 own-work portrait. One row per file in [Tests/fixtures/LICENSES.md](Tests/fixtures/LICENSES.md), enforced 1:1 by [`scripts/lint-fixtures.sh`](scripts/lint-fixtures.sh).

## License

MIT. See [LICENSE](LICENSE).
