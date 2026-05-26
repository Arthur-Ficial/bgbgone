# `shadow`

> per-subject drop shadow (translate+blur+tint+composite)

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `shadow=blur=B:offset=X,Y:opacity=O:color=#hex` |
| **Note** | introduces alpha — output here is JPEG over the source bg; use `-o out.png` for true transparent output |

## Example — red-panda, `fg:shadow=blur=12:offset=4,4:opacity=0.5:color=#000` (subject filter, background preserved)

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:shadow=blur=12:offset=4,4:opacity=0.5:color=#000" -o red-panda-shadow.jpg
```

### Via HTTP server (`bgbgone --server`)

Same operation, same output (parity verified in `Tests/integration/run-server-parity.sh`):

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:shadow=blur=12:offset=4,4:opacity=0.5:color=#000" \
  -F "format=jpg" \
  -o red-panda-shadow.jpg
```

![red-panda after `fg:shadow=blur=12:offset=4,4:opacity=0.5:color=#000`](../images/filters/shadow.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:shadow"
```

Panels (`original | bg | fg | all`):

![`shadow` panels on yoga](../images/filters/panels/yoga-shadow.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:shadow"
```

Panels (`original | bg | fg | all`):

![`shadow` panels on woman-singer](../images/filters/panels/woman-singer-shadow.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
