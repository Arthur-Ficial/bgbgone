# bgbgone — design

Date: 2026-05-22
Status: approved (in implementation)
Sibling references: [apfel](https://github.com/Arthur-Ficial/apfel), [auge](https://github.com/Arthur-Ficial/auge)

## Goal

Ultimate UNIX-style background remover for macOS. Image in, transformed image out. AI-driven via Apple Vision. 100% on-device, no deps, single binary, brew-installable. 100% scriptable — no GUI side-effects, ever.

## CLI surface

```
bgbgone [OPTIONS] [INPUT...]

# zero-config defaults
bgbgone in.jpg                          # creates in_bgbgone.png when stdout is a TTY
bgbgone in.jpg > out.png                # transparent PNG to stdout
bgbgone in.jpg > out.jpg                # JPEG if macOS exposes the stdout path
bgbgone in.jpg -o out.png               # to file
bgbgone in.jpg -o out.jpg               # infer JPEG from extension
bgbgone *.jpg --out-dir ./cutouts       # batch
cat in.png | bgbgone > out.png          # pipe
bgbgone --server                        # local HTTP API on 127.0.0.1:8787

# background replacement
--bg color:<spec>                       # solid colour: #fff | white | rgb:255,0,0
--bg image:<path>                       # image background
--bg-color <spec>                       # shared solid colour field
--bg-image <path>                       # shared background image field
--bg-fit cover|contain|tile|center      # how the bg fits the canvas

# matte / edge tuning
--mask-only                             # output the alpha mask only
--channels rgba|alpha                   # finalized image or alpha mask
--feather <px>                          # edge softening (default 1)
--threshold <0..1>                      # mask binarisation threshold
--padding <px|%>                        # extra space around subject
--crop-margin <1|2|4 values>            # API-style crop margins, px or %
--crop                                  # tight-crop to subject bbox
--roi "x1 y1 x2 y2"                     # region of interest, px or %
--scale <10%..100%|original>            # scale subject on canvas
--position <center|x% y%|original>      # position scaled subject
--semitransparency true|false           # keep or harden semi-transparent matte pixels
--shadow                                # drop shadow under cutout
--shadow-type auto|drop|3D|car|none     # shadow compatibility selector
--shadow-opacity <0..100|auto>          # shadow darkness

# algorithm
--algo auto|vn-mask|person|saliency  (default: auto)
--type auto|person|product|car|animal|graphic|transportation

# multi-instance
--multi                                 # one output per detected subject
--instance-naming "{base}-{n}.{ext}"

# output
--to, --format png|jpg|zip|heic|avif|tiff  (default: png)
--size preview|full|50MP|auto
--quality 1..100             (default: 92 for lossy)
-o, --output <path>
--out-dir <dir>

# meta
--json | --ndjson | --quiet | --verbose
--version | --help
--check                                 # capability report

# server
--server                                # run local HTTP API
--host <addr>                           # default 127.0.0.1
--port <n>                              # default 8787
--cors                                  # CORS headers for allowed origins
--allowed-origins <csv>                 # additive browser origin allowlist
--no-origin-check | --footgun           # disable browser origin checks
--token <secret> | --token-auto         # Bearer token auth
--public-health                         # unauthenticated health on exposed binds
--max-body-mb <n>                       # request body limit
```

Routing constraints are enforced before image processing starts:

- `-o` and `--out-dir` are mutually exclusive.
- Multiple file inputs cannot use `-o`; use `--out-dir` or let bgbgone write beside each input.
- Stdin input has no stable filename, so `--out-dir` is rejected; use stdout or `-o`.
- `--multi` always writes files, requires a file input stem, and cannot combine with `-o` or `--mask-only`.

## Defaults

- Output: PNG with alpha to stdout when stdout is redirected; `<stem>_bgbgone.png` when stdout is a terminal and input is a file.
- Output path inference: `-o out.jpg` selects JPEG; `> out.jpg` selects JPEG when macOS exposes the stdout file path. Opaque-only formats use white unless `--bg` is set.
- Algorithm `auto`: `VNGenerateForegroundInstanceMaskRequest`. No hidden fallback after a user explicitly chooses an unavailable algorithm.
- Single instance: cutout = union of all detected subjects (use `--multi` for one-per-instance).
- Format: PNG by default; ZIP is a stored package containing `color.jpg` and `alpha.png`.
- Quality: 92 for lossy formats (JPEG, HEIC, AVIF).
- Feather: 1px.
- Colour space: pass through input.
- Shadow / padding / crop: off.
- Server: binds to `127.0.0.1:8787`, accepts local uploads only, and uses the same processing pipeline as the CLI.

## Exit codes

- `0` success
- `1` user error (bad input file, unreadable arg)
- `2` parser error (bad flag) or no result (no subject detected; can be relaxed with `--allow-empty`)
- `3` framework error (Vision unavailable or returned an error)

## `--filter` chain (in progress, epic #1)

bgbgone v0.3.0+ adds an FFmpeg-style `--filter` flag (repeatable) for per-layer effects. The grammar is locked:

```
chain  := stage (";" stage)*
stage  := [layer ":"] filter ("," filter)*
layer  := fg | bg | all | mask    (default: all)
filter := name ("=" arg (":" arg)*)?
arg    := value | key "=" value
```

Examples:

```
--filter "bg:grayscale"
--filter "bg:blur=20"
--filter "fg:outline=color=#fff:width=3,shadow=blur=12:opacity=0.5:offset=4,4"
```

Out-of-scope filter ideas are catalogued in [`filters-out-of-scope.md`](filters-out-of-scope.md). Per-filter deep-dives land in [`filters/`](filters/) as each filter ships.

## Error model

Every error path emits a structured `BgBgOneError` (`Sources/Core/BgBgOneError.swift`). Single source of truth for rendering: `Sources/Core/ErrorRenderer.swift`. Stable code list: `Sources/Core/ErrorCodes.swift`.

Fields:

| Field      | Meaning                                                    |
|------------|------------------------------------------------------------|
| `code`     | Stable machine-readable id, e.g. `BGBG_USER_INPUT_NOT_FOUND` |
| `category` | `parser` / `user` / `no_result` / `framework`              |
| `exit`     | UNIX exit code (`0/1/2/3`) derived from `category`         |
| `message`  | Short human sentence                                       |
| `where`    | Origin pointer (flag name, file path)                      |
| `context`  | Map of key/value extras                                    |
| `hint`     | Optional suggested fix                                     |

Wire formats:

- **stderr (default):** multi-line. Honours `NO_COLOR` (no ANSI today; future) and `--quiet` (single-line message only).
- **`--json`:** stable envelope `{"ok":false,"error":{...}}`. Sibling of the success body.
- **HTTP `/v1.0/bgbgone`:** same JSON envelope. Status code: `parser` / `user` / `no_result` -> `400`; `framework` -> `500`.

Adding a new code: append to `ErrorCodes.swift` (alphabetised) and use it at the throw site. Never invent ad-hoc codes inline.

## Architecture

```
                    main.swift
                        │
              CLI.swift (parse args)
                        │
                BgBgOne.swift
              orchestrates pipeline
                        │
       ┌────────────────┼────────────────┐
       ▼                ▼                ▼
   Algorithms/      Backgrounds/      Output/
   pick + run       fetch / render    encode + write
       │                │                │
       ▼                ▼                ▼
 Vision/CoreImage  CIImage           ImageIO
                                     CGImageDestination

HTTP Server (/v1.0/*) ───────────────┘
  multipart/JSON/form uploads, optional JSON/base64 response, same Config pipeline
```

- `BgBgOneCore` library — pure Swift. No Vision / Core Image deps. Contains:
  - `Config` struct (parsed CLI state)
  - `BgBgOneError` enum
  - Argument parser (text → Config) — unit-testable without frameworks
  - Naming math (output path templates, batch fan-out)
  - Colour parsing (`#fff`, `rgb:r,g,b`, named colours)
  - Server request parsing, security policy, multipart/JSON/form parsing
- `bgbgone` executable target — depends on `BgBgOneCore` + Apple frameworks. Contains:
  - `main.swift` — install NetworkGuard, parse args, run, exit with code
  - `CLI.swift` — `--help`, `--version`, `--check` dispatch
  - `BgBgOne.swift` — pipeline orchestration
  - `Server.swift` — zero-dependency HTTP/1.1 server for local uploads
  - `Algorithms/` — one file per algorithm, conforming to `BgRemovalAlgo` protocol
  - `Compositor.swift` — mask + background (solid colour / image) → final CIImage
  - `Output.swift` — encode + write
  - `NetworkGuard.swift` — URLProtocol shim backed by the core `NetworkPolicy`
  - `BuildInfo.swift` — auto-generated by Make
- `bgbgone-tests` executable target — pure Swift test runner, no XCTest.

## Server API

The server exists for tools that need HTTP instead of a UNIX pipe. It is not a cloud client and does not fetch remote image URLs. `image_url` and `bg_image_url` return a structured `501 NOT IMPLEMENTABLE` response so the runtime no-network promise remains true.

Endpoints:

- `GET /health`
- `GET /account`
- `GET /v1.0/account`
- `POST /bgbgone`
- `POST /v1.0/bgbgone`
- `POST /improve` and `/v1.0/improve` return `501 NOT IMPLEMENTABLE`

Supported request fields for `POST /v1.0/bgbgone`:

- Input: `image_file` multipart upload or `image_file_b64`.
- Output: `format=auto|png|jpg|jpeg|zip|heic|avif|tiff|json`; `webp` returns `501 NOT IMPLEMENTABLE` on this zero-dependency encoder stack.
- Matte: `channels=rgba|alpha`.
- Background: `bg_color`, `bg_image_file`, `bg_image_file_b64`.
- Geometry: `roi`, `crop=true`, `crop_margin`, `scale`, `position`.
- Shared image controls: `quality`, `bg_fit`, `feather`, `threshold`, `shadow_type`, `shadow_opacity`, `semitransparency`.
- Subject hint: `type=auto|person|product|car|animal|graphic|transportation|saliency|vn-mask`, plus `type_level`.
- Size cap: `size=preview|full|auto|50MP`.

See `docs/server/` for the full wire contract and security matrix.

## Algorithms

| Algo | API | macOS floor | Best for |
| ---- | --- | ----------- | -------- |
| `vn-mask` | `VNGenerateForegroundInstanceMaskRequest` | 14+ | General purpose foreground subjects |
| `person` | `VNGeneratePersonSegmentationRequest` | 12+ | Portraits, people, talking-head frames |
| `saliency` | `VNGenerateObjectnessBasedSaliencyImageRequest` | 10.15+ | Objectness heat-map matte |

`--algo auto` uses the public foreground-instance mask API (`vn-mask`).
Any other algorithm name is rejected by the parser with exit code 2 — there
is no hidden fallback.

## Backgrounds

| Type | Spec syntax | Implementation |
| ---- | ----------- | -------------- |
| Solid colour | `color:#hex`, `color:named`, `color:rgb:r,g,b` | CIConstantColorGenerator |
| Image | `image:./path.jpg` | Load → fit (cover/contain/tile/centre) → composite |

Backgrounds are deliberately UNIX-shaped: the spec is a short string the shell
can construct, and the result is always a single image. To use a generated or
hand-painted background, run the generator separately, save the PNG, and pass
it via `--bg image:<path>`.

## Testing

Four layers, all green-or-fail in `make release`:

1. **Unit** (`Tests/bgbgoneTests/`, pure Swift runner) — arg parsing for every CLI flag (~190 cases), colour parsing, output naming, format inference, JSON escaping, routing validation, server compatibility request parsing, server-side security policy (origin/Bearer/X-API-Key/loopback), geometry / size / shadow / type / channels config mapping, NetworkPolicy.
2. **Integration** (`Tests/integration/run.sh`) — spawns the built binary; pipe in / pipe out / file in / file out; CLI invocations across every shared flag (`--type`, `--shadow-type`, `--scale`/`--position`, `--size`, `--semitransparency`, `--crop-margin` variants, `--roi`, all output formats, `--bg-image`/`--bg-color`); live HTTP server scenarios — CORS preflight, multi-source rejection, body limit `413`, `--no-origin-check`, `--footgun`, Bearer/X-API-Key auth, `X-Type` header policy, JSON/form/multipart bodies, ZIP output, accepted not-implementable cases.
3. **README image regeneration** (`scripts/make-readme-examples.sh`) — visual regression surface generated from the freshly installed binary.
4. **Performance** (`Tests/performance/run-100.sh`) — stages 100 fixture-backed inputs, runs five batch processes, verifies 100 outputs per run, updates the README average, and reports throughput.

Current local measurement: 100 images in 8.075s, 12.38 images/s, 80.7 ms/image.

**Fixtures:** `Tests/fixtures/` holds 16 strict public-domain images from Wikimedia (PD-NASA, PD-USGov, PD-old, PD-self, PD-Art, and pre-1929 American advertisements — never CC). The 16 break down as: 6 NASA spaceflight, 3 19th-c paintings, 3 19th/early-20th-c studio portraits, and 4 vintage product ads. `LICENSES.md` documents every fixture with source URL, PD tag, and attribution. Fixtures are checked into git for reproducible offline tests.

**Reproducible README assets:** `scripts/make-readme-examples.sh` regenerates every showcase strip in `docs/images/` from real bgbgone invocations against the PD fixtures. CI doesn't run this (it's slow); the script is the audit trail for "every README image is real."

## TDD discipline

- RED → verify failure → GREEN → verify pass → REFACTOR.
- Every new function gets a failing test first.
- Pure Swift test runner (apfel/auge pattern) — no XCTest, no Testing framework.
- `swift run bgbgone-tests` is the unit test entry point.
- Pre-commit: `make test` must be green.

## Out of scope (v1)

- Video frame extraction / re-encoding (use `ffmpeg | bgbgone | ffmpeg`).
- Photos.app library round-trip.
- UI-bound APIs (VisionKit subject lifting, document camera).
- Bundled third-party models.
- General image-editing app surface (filters / colour grading — that's `arbeit` if we ever build it).

## Pipe contract with sibling tools

```bash
bgbgone in.jpg | auge --classify                   # classify the cutout (cleaner result, no bg distractors)
bgbgone in.jpg | kern --embed-image                # cleaner embeddings
find ~/photos -name '*.heic' | bgbgone --bg color:white --to jpg --out-dir ./catalog
```

## Release process

1. `make install` (auto-bumps patch, builds release, installs to `/usr/local/bin`).
2. `make package-release-asset` → `bgbgone-<v>-arm64-macos.tar.gz`.
3. `gh release create` with the asset.
4. Update Homebrew tap formula.

(Identical to the auge release process — see `auge`'s Makefile for the canonical recipe.)
