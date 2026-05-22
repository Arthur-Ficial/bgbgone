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

- It runs the same Vision/Core Image pipeline as the CLI.
- It accepts uploaded bytes via multipart form data, URL-encoded forms, JSON, or base64 fields.
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

### `GET /account` and `GET /v1.0/account`

Returns the local account-shaped response with zero credits.

```json
{"data":{"attributes":{"credits":{"total":0,"subscription":0,"payg":0,"enterprise":0},"api":{"free_calls":0,"sizes":"all"}}}}
```

### `POST /bgbgone` and `POST /v1.0/bgbgone`

Removes or extracts the foreground from an uploaded image.

```bash
curl -X POST http://127.0.0.1:8787/v1.0/bgbgone \
    -F image_file=@photo.jpg \
    -F format=png \
    -o cutout.png
```

### `POST /improve` and `POST /v1.0/improve`

Returns `501` with a `NOT IMPLEMENTABLE` error because local bgbgone never submits images to a remote improvement program.

## Request Fields

| Field | Type | Support | Notes |
|---|---:|---|---|
| `image_file` | file | yes | Primary image upload. |
| `image_file_b64` | text | yes | Base64 image bytes. |
| `image_url` | text | NOT IMPLEMENTABLE | Remote fetches conflict with the no-network runtime. |
| `format` | text | yes | `auto`, `png`, `jpg`, `jpeg`, `zip`, `heic`, `avif`, `tiff`, or `json`. `webp` returns NOT IMPLEMENTABLE on this encoder stack. |
| `channels` | text | yes | `rgba` for image output, `alpha` for mask-only output. |
| `quality` | text | yes | `1` through `100` for lossy output formats. |
| `bg_color` | text | yes | Hex with or without `#`, named color, `rgb:r,g,b`, or `rgba:r,g,b,a`. |
| `bg_image_file` | file | yes | Uploaded replacement background image. |
| `bg_image_file_b64` | text | yes | Base64 replacement background bytes. |
| `bg_image_url` | text | NOT IMPLEMENTABLE | Remote fetches conflict with the no-network runtime. |
| `bg_fit` | text | yes | `cover`, `contain`, `tile`, or `center` for uploaded background images. |
| `feather` | text | yes | Non-negative matte edge softening radius in pixels. |
| `threshold` | text | yes | `0` through `1` matte binarisation threshold. |
| `crop` | boolean text | yes | `true`, `1`, `yes`, `y`, or `on`. |
| `crop_margin` | text | yes | One, two, or four pixel/percent values, for example `24px`, `10%`, or `5% 10%`. |
| `roi` | text | yes | Four pixel/percent coordinates: `x1 y1 x2 y2`. |
| `scale` | text | yes | `original` or `10%` through `100%`. |
| `position` | text | yes | `original`, `center`, `x%`, or `x% y%`. |
| `shadow_type` | text | yes | `auto`, `drop`, `3D`, `car`, or `none`; all enabled types map to the local drop shadow. |
| `shadow_opacity` | text | yes | `auto` or `0` through `100`. |
| `semitransparency` | boolean text | yes | `false` hardens the matte. |
| `type` | text | yes | `auto`, `person`, `product`, `car`, `animal`, `graphic`, `transportation`, `saliency`, `vn-mask`. |
| `type_level` | text | yes | `none`, `1`, `2`, or `latest`; `none` suppresses `X-Type`. |
| `size` | text | yes | `preview`, `full`, `auto`, or `50MP`; downscales only. |

Unknown fields are ignored unless they would require unsupported network behavior.

## Response Modes

Image response:

```bash
curl -X POST http://127.0.0.1:8787/v1.0/bgbgone \
    -F image_file=@photo.jpg \
    -F format=jpg \
    -F bg_color=ffffff \
    -o on-white.jpg
```

JSON response:

```bash
curl -sS -X POST http://127.0.0.1:8787/v1.0/bgbgone \
    -F image_file=@photo.jpg \
    -F format=json
```

```json
{"data":{"result_b64":"<base64 png bytes>","foreground_top":0,"foreground_left":0,"foreground_width":100,"foreground_height":100}}
```

Alpha matte:

```bash
curl -X POST http://127.0.0.1:8787/v1.0/bgbgone \
    -F image_file=@photo.jpg \
    -F channels=alpha \
    -o matte.png
```

ZIP package:

```bash
curl -X POST http://127.0.0.1:8787/v1.0/bgbgone \
    -F image_file=@photo.jpg \
    -F format=zip \
    -o result.zip
```

The ZIP contains `color.jpg` and `alpha.png`.

Successful image responses include `X-Width`, `X-Height`, `X-Credits-Charged: 0`, `X-Foreground-Top`, `X-Foreground-Left`, `X-Foreground-Width`, and `X-Foreground-Height`. `X-Type` is included unless `type_level=none`.

Unsupported local features use the normal error envelope with HTTP `501`:

```json
{"errors":[{"code":"not_implementable","title":"NOT IMPLEMENTABLE: remote image_url cannot be fetched by the local no-network runtime"}]}
```

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
