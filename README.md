# bgbgone

[![Version 1.2.7](https://img.shields.io/badge/version-1.2.7-blue)](https://github.com/Arthur-Ficial/bgbgone)
[![Swift 6.3+](https://img.shields.io/badge/Swift-6.3%2B-F05138?logo=swift&logoColor=white)](https://swift.org)
[![macOS 26+](https://img.shields.io/badge/macOS-26%2B-000000?logo=apple&logoColor=white)](https://developer.apple.com/macos/)
[![100% on-device](https://img.shields.io/badge/privacy-100%25%20on--device-green)](https://developer.apple.com/documentation/vision)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**The UNIX-style background remover for macOS. Image in, transformed image out. Apple Vision masks + Core Image. Zero dependencies. 100% on-device. 100% scriptable.**

![bgbgone hero](docs/images/hero.png)

## Install

Run `brew install Arthur-Ficial/tap/bgbgone` (macOS 26+, ~3 MB binary, no Xcode needed). From source: `make install` writes to `/usr/local/bin`.

## Quickstart — transparent cutout

Original `red-panda.jpg`:

![red-panda input](docs/images/showcase/01-panda-before.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:grayscale" -o red-panda-colourpop.jpg
```

After — background goes B&W, subject keeps its colour:

![red-panda colour-pop](docs/images/showcase/01-panda-colourpop.jpg)

## Portrait mode — silky bg blur on the same red-panda

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:blur=60" -o red-panda-portrait.jpg
```

![red-panda portrait-mode blur](docs/images/showcase/02-panda-portraitmode.jpg)

## Die-cut sticker — drop shadow + thick white outline

Original `corgi-puppy.jpg`:

![corgi-puppy input](docs/images/showcase/03-corgi-before.jpg)

```bash
bgbgone corgi-puppy.jpg --bg color:#1a2233 \
  --filter "fg:shadow=blur=40:offset=22,22:opacity=0.7:color=#000,outline=color=#fff:width=30" \
  -o corgi-sticker.jpg
```

After — clean sticker with hard die-cut edge:

![corgi-puppy die-cut sticker](docs/images/showcase/03-corgi-sticker.jpg)

## Motion-radial backdrop — `bg:zoom-blur`, `--type person`

Original `woman-singer.jpg`:

![woman-singer input](docs/images/showcase/04-woman-singer-before.jpg)

```bash
bgbgone woman-singer.jpg --type person \
  --bg "image:woman-singer.jpg" \
  --filter "bg:zoom-blur=center=0.5,0.45:amount=60" \
  -o woman-singer-zoom-blur.jpg
```

After — bg radiates outward from the subject centre, subject stays razor-sharp:

![woman-singer zoom-blur backdrop](docs/images/showcase/04-woman-singer-zoom-blur.jpg)

## Edge refinement — `mask:feather`

Original `corgi-puppy.jpg` (same fixture):

![corgi-puppy input](docs/images/showcase/03-corgi-before.jpg)

```bash
bgbgone corgi-puppy.jpg --filter "mask:feather=16" --bg color:#1a2233 -o corgi-feather16.jpg
```

After — left panel `feather=0` (razor edge) vs right panel `feather=16` (softened):

![corgi-puppy feather 0 vs 16 close-up](docs/images/feather-zoom.png)

## Pipelines — compose with sibling Apple-framework CLIs

Original `red-panda.jpg` (same fixture as Quickstart):

![red-panda input](docs/images/showcase/01-panda-before.jpg)

```bash
bgbgone red-panda.jpg -o red-panda-cutout.png && auge --classify red-panda-cutout.png
```

After — cutout fed to [auge](https://github.com/Arthur-Ficial/auge) for classification:

![bgbgone piped into auge --classify](docs/images/showcase-pipeline.png)

## Filter chain grammar

`--filter "<layer>:<name>[=args][,<name>...]; <layer>:..."`. Layers are `bg` / `fg` / `all` / `mask` / `composite`. Full catalogue with paired image per filter: [docs/filters/](docs/filters/README.md). Machine-readable surface: `bgbgone --filters-list --json`.

## Server mode

Run `bgbgone --server --host 127.0.0.1 --port 8088` to expose the same Config + pipeline over local HTTP. POSTs to `/bgbgone` accept the same options as the CLI (`bg`, `filter`, `format`, `type`, …) via multipart, JSON, or form. Full wire contract: [docs/server/README.md](docs/server/README.md). Security matrix: [docs/server/security.md](docs/server/security.md).

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

- `make test` — every lint (`lint-fixtures`, `lint-readme`, `lint-contract`, `lint-docs`, `lint-doc-images`) + unit + integration + doc-block harness
- `make install` — bump patch + build release + install to `/usr/local/bin`
- `make release` — full release gate; regenerates every shipped image asset
- `make deploy` — release + tag + push + GitHub release + Homebrew tap bump

Every fenced bash block in this README and in every doc under `docs/` is executed against the installed binary by `scripts/test-doc-blocks.sh` on every `make test`. Every `![](path)` image link is checked by `scripts/lint-doc-images.sh` — no broken images can be committed.

## Images + attribution

All 26 test fixtures are public-domain or CC0, with one CC BY 4.0 own-work portrait. One row per file in [Tests/fixtures/LICENSES.md](Tests/fixtures/LICENSES.md), enforced 1:1 by [`scripts/lint-fixtures.sh`](scripts/lint-fixtures.sh).

## License

MIT. See [LICENSE](LICENSE).
