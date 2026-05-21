# bgbgone — Project Instructions

> **apfel and auge are the golden examples.** All patterns, conventions, and guardrails from [apfel](https://github.com/Arthur-Ficial/apfel) and [auge](https://github.com/Arthur-Ficial/auge) apply here.

## Ownership & autonomy

**This is Arthur Ficial's project.** Arthur is authorised to commit, tag,
push, cut releases, and update the Homebrew tap formula directly — provided
every change meets the quality bar below. No per-commit approval needed.

Quality bar (all must be green before pushing to `main` or tagging a release):

- `make test` passes — every unit and every integration test green.
- `bash scripts/make-readme-examples.sh` re-generates cleanly; every README
  image references a real bgbgone invocation against a documented PD fixture.
- No fallbacks, no half-features, no GUI side-effects. See *NO FALLBACKS* below.
- Network is still hard-blocked at runtime by `NetworkGuard`.
- New fixtures are added to `Tests/fixtures/LICENSES.md` with verifiable PD
  justification.
- Any user-visible behaviour change (CLI surface, exit codes, `--check` output)
  is reflected in README, `--help`, and `docs/design.md` in the same commit.

External communication (emails, PRs to other projects, posts) still needs
Franz's explicit approval — only the local repo work is autonomous.

## The Golden Goal

bgbgone has ONE purpose:

> **The ultimate UNIX-style background remover for macOS. Image in, transformed image out. AI-driven via Apple Vision. 100% local. 100% scriptable.**

## NO FALLBACKS · NO HACKS · NO HALF-FEATURES

Every feature either works as a pure UNIX CLI invocation — silently, in any
context, with no GUI side-effects — or it does not ship.

There is exactly **one** code path per feature. No "try X first, fall back to Y."
If the primary path doesn't work, fix the root cause, refactor the design,
or remove the feature. Fallbacks pretend things work when they don't and rot
the codebase.

### Removed: `--bg gen:` (Apple Image Playground)

Removed in **v0.1.4**. Reason:

Apple's `ImageCreator` API (`ImagePlayground` framework) throws
`backgroundCreationForbidden` for any process that wasn't launched as a
foreground macOS app — terminal-launched CLI processes always fail. The only
workaround is to re-launch the binary via a synthesized `.app` bundle and
`open --args`, which:

1. Steals the menu bar (the `.app` becomes the frontmost application),
2. Briefly flickers the dock,
3. Cannot be scripted silently — every invocation visibly takes over the user's UI.

That violates the golden goal (100% scriptable, no GUI side-effects) and the
no-fallback rule (the `.app`-relaunch trick IS a fallback). So the feature was
removed entirely: `Sources/Backgrounds/GenerativeBg.swift` deleted, `--bg gen:`
rejected with an explanatory parser error, `--style` flag removed, `GenStyle`
enum removed, the `gen (Image Playground)` line stripped from `--check`.

Users who need a generated background should pre-generate it (Apple's
Image Playground app, any other tool) and pass it via `--bg image:<path>`.

If a future Apple API allows on-device image generation from a non-foreground
process, add it back via a single direct path — never via the `.app`-relaunch
hack.

### One mode: UNIX tool

```bash
bgbgone in.jpg                          # transparent PNG to stdout (refuses TTY)
bgbgone in.jpg -o out.png               # to file
bgbgone in.jpg --bg color:#fff          # solid color bg
bgbgone in.jpg --bg image:./bg.jpg      # image bg
cat in.png | bgbgone > out.png          # pipe
bgbgone *.jpg --out-dir ./out/          # batch
```

- Image in, image out
- Pipe-friendly, composable
- `--json` for machine consumption
- Respects `NO_COLOR`, `--quiet`, stdin/stdout TTY detection
- Correct exit codes (0 success, 1 user error, 2 no subject, 3 framework error)

### No server mode (by design)

No `--serve` flag. The UNIX pipe IS the API.

### Non-negotiable principles

- **100% on-device.** No cloud, no API keys, no network. NetworkGuard hard-blocks at runtime.
- **TDD.** No production code without a failing test first.
- **e2e integration tests use strict public-domain images only.** Wikimedia PD-NASA / PD-USGov / PD-old / PD-self. **No Creative Commons** — public domain only.
- **Clean code, clean logic.** No hacks. Proper error types.
- **Swift 6 strict concurrency.** No data races.
- **Zero dependencies.** Vision / CoreImage / ImageIO ship with macOS.

## Part of the apfel ecosystem

| Tool | What | Apple Framework |
|------|------|-----------------|
| [apfel](https://github.com/Arthur-Ficial/apfel) | LLM | FoundationModels |
| [ohr](https://github.com/Arthur-Ficial/ohr) | Speech-to-text | SpeechAnalyzer |
| [kern](https://github.com/Arthur-Ficial/kern) | Embeddings | NLContextualEmbedding |
| [auge](https://github.com/Arthur-Ficial/auge) | Vision / OCR (see) | Vision |
| **bgbgone** (this) | Background removal (do) | Vision masks + Core Image + ImageIO |

## Architecture

```
CLI args → Config (BgBgOneCore, pure) → Pipeline
                                          ↓
                                     Algorithms/   (VNRemove, VNMask, Person, Sky, Saliency)
                                          ↓
                                     Compositor    (mask + bg: SolidColor, ImageBg)
                                          ↓
                                     Output        (PNG/JPG/WebP/HEIC/AVIF/TIFF)
```

- `BgBgOneCore` library: pure Swift, no Apple framework deps, unit-testable
- Main target: Vision + Core Image integration
- Apple frameworks: `import Vision`, `import CoreImage`
- Tests: `swift run bgbgone-tests` (pure Swift runner, same pattern as auge)
- No Xcode required - builds with Command Line Tools only

## Build & Test

```bash
make install              # bump patch + build release + install to /usr/local/bin
make build                # bump patch + build release
swift build               # debug build
make test                 # unit + integration
make test-unit            # pure Swift unit tests
make test-integration     # e2e CLI tests with PD fixtures
make fixtures             # fetch Wikimedia PD test fixtures
```

**Version is in `.version` file** (single source of truth). Same auto-bump pattern as auge.

**Always use `make install` for testing changes.**

## Key Files

| Area | Files |
|------|-------|
| Entry point | `Sources/main.swift` |
| CLI commands | `Sources/CLI.swift` |
| Orchestration | `Sources/BgBgOne.swift` |
| Algorithms | `Sources/Algorithms/*.swift` |
| Compositor | `Sources/Compositor.swift` |
| Output | `Sources/Output.swift` |
| Network block | `Sources/NetworkGuard.swift` |
| Errors | `Sources/Core/BgBgOneError.swift` |
| Build info | `Sources/BuildInfo.swift` (auto-generated by `make`) |
| Tests | `Tests/bgbgoneTests/`, `Tests/integration/` |
| Test fixtures | `Tests/fixtures/` (strict-PD Wikimedia) |
| Fixture licenses | `Tests/fixtures/LICENSES.md` |
| Design | `docs/design.md` |
