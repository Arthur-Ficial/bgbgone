# Filters explicitly out of scope (v1)

Curated rejection list for the `--filter` chain (epic #1). Each item is closed by design - re-proposing requires new evidence.

| Idea | Rejected because |
|---|---|
| **Per-pixel expressions** (FFmpeg `-fx` / ImageMagick `-fx`) | Brings a full expression VM. Conflicts with the "image in, image out" goal and the deterministic-Core-Image pipeline. Users wanting this should reach for ImageMagick. |
| **Network filters** (URL-fetch backgrounds, remote LUTs, model fetch at runtime) | Violates the 100% on-device rule. `NetworkGuard` blocks all runtime HTTP/HTTPS/WS/WSS by design. |
| **Video / animation filters** | bgbgone is image in, image out. Video belongs in `ffmpeg`. Frame-pair APIs would explode scope and ship-weight. |
| **Pre-mask filters** (modify pixels BEFORE Apple Vision segmentation) | Would change the matte itself, making mask quality non-reproducible per fixture. Mask-shape filters (`mask:feather`, `mask:threshold`, etc.) operate on the post-Vision matte, which is the supported integration point. |
| **Plugin API / runtime filter loading** | Forbidden by the "no runtime plugin loading" rule in `CLAUDE.md`. Filters are first-class Swift code; new filters land via the per-filter ticket process. |
| **GUI mode** | The pipe IS the API. GUI side-effects are forbidden by the project's UNIX-only contract. The macOS GUI shell lives in a separate repo (`bgbgone-app`) and shells out to this CLI. |
| **`--filter-from-file <path>`** | Filters belong in the invocation surface so shell history + scripts capture the full transform. File-sourced chains hide intent. Shell variables solve the same problem (`F='bg:blur=20'; bgbgone in.jpg --filter "$F"`). |
| **Custom CIFilter via dlopen** | Dynamic library loading bypasses code signing, makes the binary unpredictable, and conflicts with the 3 MB single-binary distribution. |
| **Image-blending compositors** (multiply, screen, overlay over a second image) | Out of scope for v1. The `--bg image:` flag already supports compositing onto a chosen background; layered blending is a separate feature class. |

See [`docs/filters/`](filters/) for the in-scope filter catalogue once it lands (T0..T53).
