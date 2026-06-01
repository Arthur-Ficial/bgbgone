# `outline`

> coloured outline outside the matte (morphology+subtract+tint)

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `outline=color=#hex:width=N` |
| **Note** | introduces alpha — output here is JPEG over the source bg; use `-o out.png` for true transparent output |

## Example — `fg:outline=color=#ffffff:width=3`

The same operation through both transports. `scripts/gen-docs.sh` runs BOTH commands on every regen and asserts byte-identical output (parity contract). The result is shown below.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:outline=color=#ffffff:width=3" --size preview -o red-panda-outline.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:outline=color=#ffffff:width=3" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-outline.jpg
```

![red-panda after `fg:outline=color=#ffffff:width=3` — CLI render = server render (byte-identical)](../images/filters/outline.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:outline=color=#ffaa00:width=8"
```

Panels (`original | bg | fg | all`):

![`outline` panels on yoga](../images/filters/panels/yoga-outline.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:outline=color=#ffaa00:width=8"
```

Panels (`original | bg | fg | all`):

![`outline` panels on woman-singer](../images/filters/panels/woman-singer-outline.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
