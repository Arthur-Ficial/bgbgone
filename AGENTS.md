# bgbgone — Agent Instructions

See `CLAUDE.md` for project conventions. Highlights for any agent working in this repo:

## Hard rules

- **TDD.** No production code without a failing test first. Write the test, run it, watch it fail, write the minimal code, run it, watch it pass.
- **100% on-device.** No network calls from `bgbgone` itself ever. `NetworkGuard.swift` enforces this at runtime.
- **Test fixtures are strict public domain only.** Wikimedia images tagged PD-NASA, PD-USGov, PD-old, PD-self, PD-Art. **Never Creative Commons.** `Tests/fixtures/LICENSES.md` documents every fixture's source URL and PD tag.
- **No Xcode required.** Swift Package Manager via Command Line Tools.
- **`make install` after every meaningful change** to verify the release build still works.

## Workflow

1. Pick the next task from `TaskList`.
2. RED: write failing test in `Tests/bgbgoneTests/<Topic>Tests.swift` or `Tests/integration/run.sh`.
3. Run `make test-unit` (or the specific bash test). Verify it fails for the expected reason.
4. GREEN: implement minimal code in `Sources/`. Run again. Verify it passes.
5. REFACTOR if needed, keeping tests green.
6. Mark task complete. Next.

## CLI exit codes

- `0` success
- `1` user error (bad arg, file not readable)
- `2` no result (no subject detected, parser failure where exit-2-on-bad-flag matches auge)
- `3` framework error (Vision unavailable, Image Playground not enabled, capability missing)
