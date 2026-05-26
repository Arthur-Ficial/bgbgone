# bgbgone — HTTP server mode

[![Version 1.2.17](https://img.shields.io/badge/version-1.2.17-blue)](https://github.com/Arthur-Ficial/bgbgone)
[![100% on-device](https://img.shields.io/badge/privacy-100%25%20on--device-green)](https://developer.apple.com/documentation/vision)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**Same UNIX surface, over local HTTP.** `bgbgone --server` boots a zero-deps Swift HTTP server that resolves every request through the same `Config` and the same pipeline as the CLI. CLI flag `--bg` ⇄ HTTP field `bg`. CLI `--filter` ⇄ HTTP `filter`. One canonical spelling, one pipeline, byte-identical output.

> **Parity contract.** Every example below is the HTTP twin of the same example in [`README.md`](README.md). Output is byte-equivalent. Proof: [`Tests/integration/run-server-parity.sh`](Tests/integration/run-server-parity.sh) (19 cases, all green).

![bgbgone hero](docs/images/hero.png)

## Contents

- [Start the server](#start-the-server)
- [Inputs used in this README](#inputs-used-in-this-readme)
- **Output modes — red-panda**
  - [Transparent cutout](#transparent-cutout-on-red-panda)
  - [Alpha matte (`channels=alpha`)](#alpha-matte-on-red-panda-channelsalpha)
  - [Solid-colour background](#solid-colour-background-on-red-panda)
  - [Universe-photo background](#universe-photo-background-on-red-panda)
- **Filter chain — single-fixture demos**
  - [Colour-pop on red-panda](#colour-pop-on-red-panda)
  - [Portrait mode on red-panda](#portrait-mode-on-red-panda)
  - [Die-cut sticker on corgi-puppy](#die-cut-sticker-on-corgi-puppy)
  - [Motion-radial backdrop on woman-singer](#motion-radial-backdrop-on-woman-singer)
  - [Edge refinement on corgi-puppy](#edge-refinement-on-corgi-puppy-maskfeather)
- [Endpoints + wire contract](#endpoints--wire-contract)
- [Security](#security)
- [Server flags](#server-flags)
- [Back to CLI README](README.md)

## Start the server

Bind to loopback so the server stays local-only.

```bash
bgbgone --server --host 127.0.0.1 --port 8787
```

Every example below assumes `http://127.0.0.1:8787` as the base URL.

## Inputs used in this README

Three originals drive every example below. Each is shown once here.

| `red-panda.jpg` | `corgi-puppy.jpg` | `woman-singer.jpg` |
|---|---|---|
| ![red-panda original](docs/images/showcase/01-panda-before.jpg) | ![corgi-puppy original](docs/images/showcase/03-corgi-before.jpg) | ![woman-singer original](docs/images/showcase/04-woman-singer-before.jpg) |

## Transparent cutout on red-panda

Default: bgbgone removes the background and returns a PNG with alpha. Equivalent to `bgbgone red-panda.jpg -o red-panda-cutout.png`.

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "format=png" \
  -o red-panda-cutout.png
```

![red-panda transparent cutout (checkerboard shows alpha)](docs/images/red-panda/cutout.png)

## Alpha matte on red-panda (`channels=alpha`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "format=png" \
  -F "channels=alpha" \
  -o red-panda-matte.png
```

![red-panda alpha matte — silhouette as grayscale](docs/images/red-panda/matte.png)

## Solid-colour background on red-panda

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "format=jpg" \
  -F "bg=color:#1a2233" \
  -o red-panda-on-navy.jpg
```

![red-panda on a solid navy background](docs/images/red-panda/on-navy.jpg)

## Universe-photo background on red-panda

Multipart upload accepts a `bg=@<path>` form field for the background image.

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "format=jpg" \
  -F "bg=@nebula-flaming-star.png" \
  -o red-panda-in-space.jpg
```

![red-panda composited onto the Flaming Star Nebula](docs/images/red-panda/in-space.jpg)

## Colour-pop on red-panda

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "format=jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=bg:grayscale" \
  -o red-panda-colourpop.jpg
```

![red-panda colour-pop](docs/images/showcase/01-panda-colourpop.jpg)

## Portrait mode on red-panda

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "format=jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=bg:blur=60" \
  -o red-panda-portrait.jpg
```

![red-panda portrait-mode blur](docs/images/showcase/02-panda-portraitmode.jpg)

## Die-cut sticker on corgi-puppy

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@corgi-puppy.jpg" \
  -F "format=png" \
  -F "filter=fg:outline=color=#ffffff:width=30" \
  -F "crop=true" \
  -F "crop-margin=8%" \
  -o corgi-sticker.png
```

![corgi-puppy die-cut sticker — hard solid white border, transparent background](docs/images/showcase/03-corgi-sticker.png)

## Motion-radial backdrop on woman-singer

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@woman-singer.jpg" \
  -F "format=jpg" \
  -F "type=person" \
  -F "bg=@woman-singer.jpg" \
  -F "filter=bg:zoom-blur=center=0.5,0.45:amount=60" \
  -o woman-singer-zoom-blur.jpg
```

![woman-singer zoom-blur backdrop](docs/images/showcase/04-woman-singer-zoom-blur.jpg)

## Edge refinement on corgi-puppy (`mask:feather`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@corgi-puppy.jpg" \
  -F "format=jpg" \
  -F "bg=color:#1a2233" \
  -F "filter=mask:feather=16" \
  -o corgi-feather16.jpg
```

![corgi-puppy mask:feather at 0, 24, and 80](docs/images/feather-zoom.png)

## Endpoints + wire contract

Two routes; full schema in [`docs/server/README.md`](docs/server/README.md).

- **`GET /health`** — returns `{"status":"ok","version":"...","api":"bgbgone","local":true}`. Public on loopback even when `--token` is set.
- **`POST /bgbgone`** — accepts `multipart/form-data`, `application/json`, or `application/x-www-form-urlencoded`. The source field is always `image_file` (multipart part or base64 text). Every CLI flag has a matching field with the same name (drop the leading `--`).

Successful image responses include `X-Width`, `X-Height`, `X-Credits-Charged: 0`, `X-Foreground-{Top,Left,Width,Height}`. JSON responses ship the same `{"ok":true,"schema":"bgbgone.run.v1","result":...}` envelope as CLI `--json`.

## Security

Full matrix: [`docs/server/security.md`](docs/server/security.md). Defaults:

- Binds to `127.0.0.1` only — no remote access.
- Browser `Origin` checks for `http://127.0.0.1`, `http://localhost`, `http://[::1]`. Disable with `--no-origin-check` (curl always allowed).
- `NetworkGuard` still hard-blocks any outbound `http` / `https` / `ws` / `wss` inside the process — no remote URL fetching, no analytics, no model download.
- Bearer / `X-API-Key` auth via `--token <secret>` or `--token-auto`.

## Server flags

```text
--server
--host <addr>             # default 127.0.0.1
--port <n>                # default 8787
--cors                    # opt-in CORS headers for allowed origins
--allowed-origins <csv>   # additive
--no-origin-check         # disable browser origin filtering
--token <secret>          # Bearer / X-API-Key auth (also $BGBGONE_TOKEN)
--token-auto              # random token printed once to stderr
--public-health           # /health stays public on non-loopback binds
--max-body-mb <n>         # request body limit (default 32, max 512)
--footgun                 # no-origin-check + wildcard CORS (demos only)
```

## Back to CLI README

The CLI surface is the canonical entry point. [`README.md`](README.md) walks through every example with the `bgbgone <flags>` invocation. Output is byte-identical to the curl twin above.
