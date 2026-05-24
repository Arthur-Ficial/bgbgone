# bgbgone Server

`bgbgone --server` runs a local HTTP API for clients that need request/response integration instead of UNIX pipes.

Default bind:

```bash
bgbgone --server
```

Base URL:

```text
http://127.0.0.1:8787
```

The server is local-first by design:

- It runs the same Vision/Core Image pipeline as the CLI through the same `Config`. There is no parallel processing path.
- Every request field is the long-form CLI flag name: `--bg` → `bg`, `--format` → `format`, `--type` → `type`, `--crop-margin` → `crop-margin`, `--shadow-type` → `shadow-type`, `--filter` → `filter`, and so on. One name per concept across both surfaces.
- It accepts uploaded bytes via multipart form data, URL-encoded forms, or JSON. The source field is always `image_file` (multipart file part *or* base64 text).
- It does not fetch remote image URLs.
- `NetworkGuard` still blocks outbound HTTP, HTTPS, WS, and WSS URL loading inside the process.
- It does not require an API key by default. When `--token` is set, clients may authenticate with either `Authorization: Bearer <token>` or `X-API-Key: <token>`.

## Endpoints

### `GET /health`

Returns server status.

```json
{"status":"ok","version":"0.1.x","api":"bgbgone","local":true}
```

On loopback binds, `/health` stays public even when `--token` is set. On non-loopback binds, token auth applies unless `--public-health` is set.

### `POST /bgbgone`

Removes or extracts the foreground from an uploaded image.

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
    -F image_file=@photo.jpg \
    -F format=png \
    -o cutout.png
```

## Request Fields

| Field | Type | Support | Notes |
|---|---:|---|---|
| `image_file` | file | yes | Primary image upload. |
| `image_file` | text | yes | Base64 image bytes for JSON or URL-encoded bodies. |
| `format` | text | yes | `auto`, `png`, `jpg`, `zip`, `heic`, `avif`, `tiff`, or `json`. |
| `channels` | text | yes | `rgba` for image output, `alpha` for mask-only output. |
| `quality` | text | yes | `1` through `100` for lossy output formats. |
| `bg` | text | yes | Same grammar as CLI: `color:<spec>` or `image:<path>`. |
| `bg` | file | yes | Uploaded replacement background image. |
| `bg-fit` | text | yes | `cover`, `contain`, `tile`, or `center` for uploaded background images. |
| `filter` | text | yes | Same filter grammar as CLI, repeatable by comma/semicolon inside the value. |
| `crop` | boolean text | yes | `true`, `1`, `yes`, `y`, or `on`. |
| `crop-margin` | text | yes | One, two, or four pixel/percent values: `24px`, `10%`, `5% 10%`, or `5% 10% 15% 20%`. Single-value form replaces the legacy `padding` field. |
| `roi` | text | yes | Four pixel/percent coordinates: `x1 y1 x2 y2`. |
| `shadow-type` | text | yes | `auto`, `drop`, `3D`, `car`, or `none`. `none` disables the drop shadow; any other value enables it. |
| `shadow-opacity` | text | yes | `auto` or `0` through `100`. |
| `semitransparency` | boolean text | yes | `false` hardens the matte. |
| `type` | text | yes | `auto`, `person`, `product`, `car`, `animal`, `graphic`, `transportation`, `saliency`, `vn-mask`. Same vocabulary as the CLI `--type` flag. |
| `type-level` | text | yes | `none`, `1`, `2`, or `latest`; `none` suppresses `X-Type`. |
| `size` | text | yes | `preview`, `full`, `auto`, or `50MP`; downscales only. |

Unknown fields return HTTP `400` with the normal JSON error envelope.

## Response Modes

Image response:

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
    -F image_file=@photo.jpg \
    -F format=jpg \
    -F bg=color:#ffffff \
    -o on-white.jpg
```

JSON response:

```bash
curl -sS -X POST http://127.0.0.1:8787/bgbgone \
    -F image_file=@photo.jpg \
    -F format=json
```

```json
{"ok":true,"schema":"bgbgone.run.v1","result":{"input":"/tmp/input.jpg","output":"-","algo":"vn-mask","format":"png","width":100,"height":100,"filters":[],"image_b64":"<base64 png bytes>"}}
```

Alpha matte:

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
    -F image_file=@photo.jpg \
    -F channels=alpha \
    -o matte.png
```

ZIP package:

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
    -F image_file=@photo.jpg \
    -F format=zip \
    -o result.zip
```

The ZIP contains `color.jpg` and `alpha.png`.

Successful image responses include `X-Width`, `X-Height`, `X-Credits-Charged: 0`, `X-Foreground-Top`, `X-Foreground-Left`, `X-Foreground-Width`, and `X-Foreground-Height`. `X-Type` is included unless `type-level=none`.

Invalid input uses the same `ok:false` JSON envelope as CLI `--json`.

## Server Flags

```text
--server
--host <addr>             # default 127.0.0.1
--port <n>                # default 8787, valid 1..65535
--cors                    # opt-in CORS headers for allowed origins
--allowed-origins <csv>   # ADDITIVE; defaults include http://127.0.0.1, http://localhost, http://[::1]
--no-origin-check         # disable browser Origin filtering (curl is already allowed)
--token <secret>          # require Bearer / X-API-Key (also honoured via $BGBGONE_TOKEN)
--token-auto              # generate a random token at startup, printed once to stderr
--public-health           # keep /health public when --token is set on a non-loopback bind
--max-body-mb <n>         # request body limit in MiB; default 32, max 512
--footgun                 # shorthand: no origin check + wildcard CORS (demos only)
```

### Environment overrides

| Variable | Behaviour |
|---|---|
| `BGBGONE_TOKEN` | Pre-seeds the required token; `--token` on the CLI still wins. |
| `BGBGONE_HOST` | Pre-seeds the bind host (overridden by `--host`). |
| `BGBGONE_PORT` | Pre-seeds the bind port; ignored if outside `1..65535`. |

See [security.md](security.md) for the full auth and origin matrix.
