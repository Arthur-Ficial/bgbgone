# Server Security

The server is intended for local automation first. It binds to `127.0.0.1` by default and protects browser-facing use with origin checks. Non-browser tools such as `curl` usually omit the `Origin` header and are allowed.

## Defaults

```bash
bgbgone --server
```

```text
endpoint: http://127.0.0.1:8787
origin: localhost only
cors: disabled
token: none
```

Default allowed origins:

```text
http://127.0.0.1
http://localhost
http://[::1]
```

Port variants and HTTPS variants of those origins are accepted. Prefix attacks such as `http://localhost.example.com` are rejected.

## CORS

Enable CORS for trusted local browser apps:

```bash
bgbgone --server --cors --allowed-origins http://localhost:3000
```

Preflight response:

```bash
curl -X OPTIONS -D - http://127.0.0.1:8787/v1.0/bgbgone \
    -H 'Origin: http://localhost:3000' \
    -H 'Access-Control-Request-Headers: Content-Type, Authorization' \
    -o /dev/null
```

The server returns:

```text
204 No Content
Access-Control-Allow-Origin: http://localhost:3000
Access-Control-Allow-Methods: GET, POST, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
```

`--cors` does not disable origin checks. Use `--allowed-origins` to add trusted browser origins.

## Token Auth

No API key is required by default. Require a local token only when exposing the server beyond trusted local automation:

```bash
bgbgone --server --token "$(openssl rand -hex 16)"
```

Request:

```bash
curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8787/v1.0/account
```

The same token is also accepted through `X-API-Key` for clients that already send that header:

```bash
curl -H "X-API-Key: $TOKEN" http://127.0.0.1:8787/v1.0/account
```

Environment variable:

```bash
export BGBGONE_TOKEN="$TOKEN"
bgbgone --server
```

Generate a random token at startup:

```bash
bgbgone --server --token-auto
```

The generated token is printed once in the startup banner.

## Non-Loopback Binds

For LAN use, bind to all interfaces and require auth:

```bash
bgbgone --server --host 0.0.0.0 --token-auto
```

On non-loopback binds, `/health` requires the token unless explicitly made public:

```bash
bgbgone --server --host 0.0.0.0 --token-auto --public-health
```

## Origin Check Matrix

| Flags | Origin check | CORS | Token | Browser access |
|---|---|---|---|---|
| default | localhost only | no | no | localhost simple requests |
| `--cors` | localhost only | yes | no | localhost browser apps |
| `--cors --allowed-origins X` | defaults plus X | yes | no | listed origins |
| `--token X` | localhost only | no | yes | token holders |
| `--cors --token X` | localhost only | yes | yes | localhost token holders |
| `--no-origin-check` | disabled | no | optional | any origin for simple requests |
| `--footgun` | disabled | yes | optional | any origin |

`--footgun` is shorthand for disabling origin checks and enabling wildcard CORS. Use it only for controlled demos or disposable local experiments.

## Request Limits

Default body limit:

```text
32 MiB
```

Override:

```bash
bgbgone --server --max-body-mb 64
```

Requests above the limit receive HTTP `413`.
