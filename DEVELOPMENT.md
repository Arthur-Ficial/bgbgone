# DEVELOPMENT.md - bgbgone working agreement

This is the contract every contributor (human or AI session) accepts before touching code.

Architecture lives in [`docs/design.md`](docs/design.md). AI-session-specific instructions live in [`CLAUDE.md`](CLAUDE.md). This file is the *working agreement*: discipline, cadence, gates. No content duplicated here that belongs in those files; cross-link instead.

---

## 1. Golden goal

> The ultimate UNIX-style background remover for macOS. Image in, transformed image out. AI-driven via Apple Vision. 100% local. 100% scriptable.

See [`CLAUDE.md`](CLAUDE.md) for the full goal statement and the apfel-ecosystem context.

---

## 2. Hard rules (13 non-negotiables, from epic #1)

Every commit, every ticket, every contributor. No exceptions.

1. **Fail early, fail hard. NO FALLBACKS.** One code path per feature. No `try?` swallowing, no silent defaults, no `if primary { ... } else { fallback }`. Validation at the boundary (parser); rest of the code asserts invariants without defensive guards.
2. **TDD red -> green -> refactor.** Every ticket starts with one or more failing tests proving the absence of the feature. Implementation lands only enough code to make them pass. Refactor only with green tests.
3. **Every commit on `main` is fully green.** No skipped tests, no `xfail`, no commented-out tests, no `// TODO: re-enable`. Removals migrate tests in the same commit.
4. **No legacy. No deprecation. No half-features.** Old flags / APIs / code paths deleted the moment a replacement lands, in the same commit. No `if --old-flag { warn }` shims. No "deprecated" log lines.
5. **GitHub push after every meaningful unit.** Each filter / refactor / fix is its own commit and its own push. The remote is the source of truth.
6. **`make release` green before every push.** Tests + install + README image regeneration against the freshly installed binary + packaging. Never skipped.
7. **README regenerated on every visible-output change.** `scripts/make-readme-examples.sh` reruns in the same commit; assets ship with the commit.
8. **100% UNIX style, with a first-class local server surface.** stdin/stdout, pipes, TTY refusal on binary stdout, `NO_COLOR`, `--quiet`, `--json`, correct exit codes (0/1/2/3). `--server` is allowed only as a local HTTP transport over the same `Config` and pipeline: no GUI, no cloud daemon, no runtime plugin loading.
9. **100% local at runtime.** `NetworkGuard` hard-blocks `http`/`https`/`ws`/`wss`. SPM build-time package resolution is fine; runtime network access is not.
10. **No performance regression.** No-filter run within 2% of current `main`. Chain rasterises once via one shared `CIContext`. Budgets in section 5.
11. **Docs in the same commit as code.** `README.md`, `--help`, `docs/design.md`, `docs/server/`, `bgbgone --filters-list`, `Tests/fixtures/LICENSES.md` (if new fixtures) all updated in the same commit that introduces or changes behaviour. `make lint` must pass; `scripts/lint-contract.sh` guards the single CLI/server surface, SSOT defaults, and removed-alias drift.
12. **Clean code.** Files <=150 lines, functions <=30 lines, no magic values, named exports, single responsibility, no boolean params, no >4 params, no commented-out code, no TODO comments, no clever code.
13. **Industry-standard deps OK; do not reinvent.** Battle-tested system frameworks (Core Image, Vision, Accelerate, ImageIO) and Swift packages (`swift-argument-parser`, `CIFilterFactory`). No GPUImage. No ImageMagick. See section 6.

---

## 3. TDD procedure (red -> green -> refactor)

Per ticket, in order:

**RED**
1. Add a failing test that asserts a non-trivial behaviour (pixel property, exit code + diagnostic, structural invariant). Not "does not crash".
2. Run `make test`. Confirm the new test fails.
3. Commit the failing test alone. Push. (The RED commit is allowed on `main` in active development; the next commit makes it green.)

**GREEN**
4. Implement the minimum code to make the test pass. One Swift file per filter under `Sources/Filters/<Name>.swift`. Register in `FilterRegistry`. Use the shared `CIContext`.
5. Run `make test`. All tests and contract lints green, not only the new ones.

**REFACTOR**
6. Extract shared helpers if two implementations duplicate logic. Tests stay green.

**DOCS (same commit as GREEN)**
7. `README.md` filter section: add row. `--help` regenerates from the registry. `bgbgone --filters-list` auto-includes the new filter (after T58 #60). `scripts/make-readme-examples.sh` extended to render the showcase image - regenerate, visually review. `docs/design.md` catalogue table updated.

**RELEASE GATE**
8. `make release` green: lints + tests + install + README image regen + packaging.

**PUSH**
9. `git add -A && git commit -m "..."`. Review staged files; never `git add .` blindly. Commit message references the ticket id (`TNN #issue`) and the test that proves it.
10. `git push origin <branch>`.

---

## 4. Per-feature UNIX checklist

Run this against every new flag / filter / feature before declaring done:

- [ ] stdin input works: `cat in.jpg | bgbgone <flags> > out.png`
- [ ] stdout output works; TTY refusal on binary stdout preserved
- [ ] pipe-composes with itself for pure pixel filters (mask-consuming filters cannot pipe-compose - documented in `--help`)
- [ ] `--json` includes the new field/chain in run metadata
- [ ] `--quiet` suppresses any informational stderr from the new path
- [ ] `NO_COLOR=1` suppresses ANSI escape sequences
- [ ] parse errors exit with code 2 + diagnostic naming the offending substring and position
- [ ] batch mode (`--out-dir`) applies the new behaviour to every input
- [ ] no whole-output buffering in RAM regression

---

## 5. Performance budget

Gated in CI via `Tests/performance/`. Captured in `Tests/performance/baseline.json` (created in T4 #6).

| Scenario | Budget |
|---|---|
| No-filter run on standard fixtures | <= current `main` + 2% noise |
| Single-filter run (e.g. `bg:blur=10`) on 4 MP fixture | <= no-filter + 200 ms |
| Five-filter chain on 4 MP fixture | <= no-filter + 500 ms |
| Sustained throughput (`run-sustained.sh`) | no regression with a Tier-1 chain on every image |

Cannot meet budget -> the feature does not ship until it can. No "fast path / slow path" branches. One code path.

---

## 6. Dependency policy

**Allowed (Apple-provided, zero ship-weight cost):** Core Image (`CIFilter`, `CIImage`, `CIContext`), Vision (matte requests), Accelerate / vImage (pixel-level ops where Core Image is missing what we need), ImageIO (`CGImageSource`, `CGImageDestination`), Metal Performance Shaders (only if CI/CPU dispatch underperforms).

**Allowed (Swift Package Manager):** `swift-argument-parser` (Apple, BSD) for CLI; `CIFilterFactory` (dagronf, MIT) for typed Swift wrappers over `CIFilter`; `swift-parsing` (Pointfree, MIT) *only if* the hand-rolled filter DSL tokeniser becomes unwieldy.

**Banned:** GPUImage / GPUImage3 (owns its own pipeline, conflicts with ours). ImageMagick (heavy, overlaps Core Image, not Swift-native). Any C-library wrapper requiring a build step beyond SPM resolve. Any package without a commit in the last 12 months, or under 100 stars without institutional backing.

**Hygiene:** `Package.resolved` committed. Versions pinned to minor (`from: "1.5.0"`, not `branch:`). New dep -> justification in the commit message.

---

## 6a. Error model

Errors flow through `BgBgOneError` (struct with `code` / `category` / `message` / `where` / `context` / `hint`) - see [`docs/design.md`](docs/design.md) section "Error model" for the wire formats and code-naming convention. Adding a new failure mode means appending one entry to `Sources/Core/ErrorCodes.swift` and using it at the throw site. Never invent inline ad-hoc codes; never reuse a code for a semantically different failure.

## 7. Commit message conventions

- `filter: <name> (TNN #issue)` - one filter landing, GREEN phase
- `RED tests for <feature>` - failing-test-only commit
- `TNN #issue: <description>` - foundation / housekeeping ticket
- `docs: <what>` - doc-only change
- `v0.X.Y - <what>` - version bump after a release-gated push

Reference the ticket id (`TNN`) and GitHub issue number (`#NN`) in every commit that closes scope from epic #1.

---

## 8. Release gate

`make release` runs, in order: `make test` (unit + integration) -> `make install` (writes `.build/release/bgbgone` to `$PREFIX/bin`) -> `make readme-images` (regenerates every showcase asset via `scripts/make-readme-examples.sh` against the freshly installed binary) -> `make performance-100` (perf gate) -> `make package-release-asset` (tarball + sha256).

Every push waits on this. Tagging without `make release` green is forbidden - documented in [`CLAUDE.md`](CLAUDE.md) section "Quality bar".

Source: [`Makefile`](Makefile), [`scripts/make-readme-examples.sh`](scripts/make-readme-examples.sh).
