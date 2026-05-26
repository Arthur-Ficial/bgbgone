# bgbgone — design

Internal architecture + invariants. User-facing usage lives in [README.md](../README.md).
For the live CLI surface run `bgbgone --help` or `bgbgone --check`.

## Layers

```
                main.swift                ← install NetworkGuard, parse args, exit
                    │
              ConfigParser                ← pure Swift, no Apple deps
                    │
                BgBgOne                   ← pipeline orchestrator
                    │
       ┌────────────┼─────────────┬─────────────┐
       ▼            ▼             ▼             ▼
   Algorithms/   FilterPipeline   Compositor    Output
   Vision masks  49 Core Image    mask + bg     ImageIO / CGImageDestination
                 filters          → CIImage     (PNG / JPG / HEIC / AVIF / TIFF / ZIP)
                                      ▲
                                      │
                              NetworkGuard (URLProtocol shim, hard-blocks at runtime)

HTTP /bgbgone  ── resolved through the same ConfigParser + same pipeline ──┘
```

- `BgBgOneCore` library — pure Swift. Parses args, holds `Config`,
  `BgBgOneError`, colour parser, output-name math, server request parsing,
  security policy. Unit-testable without frameworks.
- `bgbgone` executable target — depends on `BgBgOneCore` + Vision +
  CoreImage + ImageIO. Wires the pipeline, ships the HTTP server.
- `bgbgone-tests` executable target — pure Swift test runner, no XCTest.

## Filter chain grammar

```
chain  := stage (";" stage)*
stage  := [layer ":"] filter ("," filter)*
layer  := bg | fg | all | mask | composite     (default: all)
filter := name ("=" arg (":" arg)*)?
arg    := value | key "=" value
```

Composite-only filters (`vignette`, `vignette-effect`, `bloom`, `gloom`)
must appear in a trailing `composite:` stage — they run after the
foreground/background split is flattened. The parser rejects any
fg/bg/all/mask stage placed after a composite stage.

Filter registry is the single SSOT, emitted by
`bgbgone --filters-list --json`. Used by `scripts/gen-docs.sh` to render
every per-filter page from one template. Docs cannot drift from the
binary.

## Error model

Every error path is a structured `BgBgOneError`
(`Sources/Core/BgBgOneError.swift`). Renderer + stable codes:
`Sources/Core/ErrorRenderer.swift`, `Sources/Core/ErrorCodes.swift`.

| Field      | Meaning                                                      |
|------------|--------------------------------------------------------------|
| `code`     | Stable machine-readable id, e.g. `BGBG_USER_INPUT_NOT_FOUND` |
| `category` | `parser` / `user` / `no_result` / `framework`                |
| `exit`     | UNIX exit code (`0/1/2/3`) derived from `category`           |
| `message`  | Short human sentence                                         |
| `where`    | Origin (flag name, file path)                                |
| `context`  | key/value extras                                             |
| `hint`     | Optional suggested fix                                       |

Wire formats:

- **stderr (default):** multi-line. `--quiet` collapses to single-line.
- **`--json`:** stable envelope `{"ok":false,"schema":"bgbgone.run.v1","error":{...}}`.
- **HTTP `/bgbgone`:** same envelope. Status: parser/user → `400`,
  no_result → `422`, framework → `500`.

Never invent ad-hoc codes inline — append to `ErrorCodes.swift` and use
it at the throw site.

## Algorithms

| Internal | `--type` selectors that resolve to it | Vision API | macOS floor |
|----------|---------------------------------------|------------|-------------|
| `vn-mask` | `auto`, `vn-mask`, `product`, `car`, `animal`, `graphic`, `transportation` | `VNGenerateForegroundInstanceMaskRequest` | 14+ |
| `person`  | `person`                              | `VNGeneratePersonSegmentationRequest`       | 12+ |
| `saliency`| `saliency`                            | `VNGenerateObjectnessBasedSaliencyImageRequest` | 10.15+ |

No hidden fallback after a user explicitly chooses an unavailable
algorithm. Any other value is rejected by the parser with exit 2.

## Backgrounds

| Type   | Spec                                      | Implementation                         |
|--------|-------------------------------------------|----------------------------------------|
| Solid  | `color:#hex` / `color:named` / `color:rgb:r,g,b` | CIConstantColorGenerator               |
| Image  | `image:./path.jpg`                         | Load → fit (cover / contain / tile / center) → composite |

UNIX-shaped: a short shell-constructible spec, output is always a single
image. Generated backgrounds: produce the PNG separately, then pass via
`--bg image:<path>`.

## Routing constraints

Enforced before image processing starts:

- `-o` and `--out-dir` are mutually exclusive.
- Multiple file inputs cannot use `-o` (use `--out-dir` or default beside-input).
- Stdin input has no stable filename → `--out-dir` rejected.
- `--multi` always writes files; requires a file input stem; cannot combine
  with `-o` or `--channels alpha`.

## Testing layers

All green-or-fail in `make release`:

1. **`lint-fixtures`** — every image in `Tests/fixtures/` has exactly one
   row in `LICENSES.md`.
2. **`lint-readme`** — README must not reference hard-removed v1.0 flags.
3. **`lint-contract`** — SSOT contract checks on CLI/server flag aliases.
4. **`lint-docs`** — every `--filter "..."` chain in every shipped .md
   parses against the real binary.
5. **`test-unit`** — pure Swift, no frameworks (~190 cases).
6. **`test-integration`** — spawns the built binary; CLI flags + HTTP
   server scenarios + e2e against every fixture (232+ assertions).
7. **`test-doc-blocks`** — every fenced ```bash block in every shipped
   .md is executed against the installed binary in a scratch dir with
   fixture symlinks. Exit 0 required.
8. **`performance-100`** — 5 × 100-image batches, throughput reported.

`make all-images` regenerates every shipped image asset
(`docs/images/**`, per-filter showcase, per-filter panels) from the
freshly-installed binary so README assets cannot diverge from output.

## Pipe contract with sibling tools

```bash
bgbgone in.jpg | auge --classify                   # classify the cutout
bgbgone in.jpg | kern --embed-image                # cleaner embeddings
find ~/photos -name '*.heic' | bgbgone --bg color:white --format jpg --out-dir ./catalog
```

## Out of scope (v1)

- Video frame extraction / re-encoding (use `ffmpeg | bgbgone | ffmpeg`).
- Photos.app library round-trip.
- UI-bound APIs (VisionKit subject lifting, document camera).
- Bundled third-party models.
- General image-editing app surface (colour grading beyond the 49
  shipped filters — see [filters-out-of-scope.md](filters-out-of-scope.md)).

## Release

`make deploy` chains: bump patch → release gate (every lint + every
test + every-image regen) → tag → push → GitHub release → Homebrew tap
bump. Never tag without it.
