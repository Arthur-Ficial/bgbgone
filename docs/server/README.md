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
- It accepts uploaded bytes via multipart form data or base64 form fields.
- It does not fetch remote image URLs.
- `NetworkGuard` still blocks outbound HTTP, HTTPS, WS, and WSS URL loading inside the process.

## Endpoints

### `GET /health`

Returns server status.

```json
{"status":"ok","version":"0.1.x","api":"bgbgone","local":true}
```

On loopback binds, `/health` stays public even when `--token` is set. On non-loopback binds, token auth applies unless `--public-health` is set.

### `GET /v1.0/account`

Returns a small local capability marker.

```json
{"api":"bgbgone","version":"0.1.x","local":true}
```

### `POST /v1.0/bgbgone`

Removes or extracts the foreground from an uploaded image.

```bash
curl -X POST http://127.0.0.1:8787/v1.0/bgbgone \
    -F image_file=@photo.jpg \
    -F format=png \
    -o cutout.png
```

## Request Fields

| Field | Type | Support | Notes |
|---|---:|---|---|
| `image_file` | file | yes | Primary image upload. |
| `image_file_b64` | text | yes | Base64 image bytes. |
| `image_url` | text | no | Rejected; upload bytes instead. |
| `format` | text | yes | `png`, `jpg`, `jpeg`, `heic`, `avif`, `tiff`, or `json`. Default: `png`. |
| `channels` | text | yes | `rgba` for image output, `alpha` for mask-only output. |
| `bg_color` | text | yes | Hex with or without `#`, named color, `rgb:r,g,b`, or `rgba:r,g,b,a`. |
| `bg_image_file` | file | yes | Uploaded replacement background image. |
| `bg_image_file_b64` | text | yes | Base64 replacement background bytes. |
| `bg_image_url` | text | no | Rejected; upload bytes instead. |
| `crop` | boolean text | yes | `true`, `1`, `yes`, `y`, or `on`. |
| `crop_margin` | text | yes | Pixel number or percent, for example `24` or `10%`. |
| `add_shadow` | boolean text | yes | Adds the same drop shadow as CLI `--shadow`. |
| `type` | text | yes | `auto`, `person`, `product`, `car`, `saliency`, `vn-mask`. |
| `size` | text | accepted | Compatibility no-op; output size is the processed image size. |

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
{"data":{"result_b64":"<base64 png bytes>"}}
```

Alpha matte:

```bash
curl -X POST http://127.0.0.1:8787/v1.0/bgbgone \
    -F image_file=@photo.jpg \
    -F channels=alpha \
    -o matte.png
```

## Server Flags

```text
--server
--host <addr>
--port <n>
--cors
--allowed-origins <csv>
--no-origin-check
--token <secret>
--token-auto
--public-health
--max-body-mb <n>
```

See [security.md](security.md) for the full auth and origin matrix.
