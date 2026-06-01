# `opacity`

> scale alpha by value 0..1 (CIColorMatrix)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `opacity=value` |
| **Note** | introduces alpha — output here is JPEG over the source bg; use `-o out.png` for true transparent output |

## Example — `fg:opacity=0.7`

The same operation through both transports. `scripts/gen-docs.sh` runs BOTH commands on every regen and asserts byte-identical output (parity contract). The result is shown below.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:opacity=0.7" --size preview -o red-panda-opacity.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:opacity=0.7" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-opacity.jpg
```

![red-panda after `fg:opacity=0.7` — CLI render = server render (byte-identical)](../images/filters/opacity.jpg)



See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
