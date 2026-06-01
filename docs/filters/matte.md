# `matte`

> emit the alpha mask itself as final RGBA

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `matte` |
| **Note** | introduces alpha — output here is JPEG over the source bg; use `-o out.png` for true transparent output |

## Example — `fg:matte`

The same operation through both transports. `scripts/gen-docs.sh` runs BOTH commands on every regen and asserts byte-identical output (parity contract). The result is shown below.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:matte" --size preview -o red-panda-matte.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:matte" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-matte.jpg
```

![red-panda after `fg:matte` — CLI render = server render (byte-identical)](../images/filters/matte.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:matte"
```

Panels (`original | bg | fg | all`):

![`matte` panels on yoga](../images/filters/panels/yoga-matte.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:matte"
```

Panels (`original | bg | fg | all`):

![`matte` panels on woman-singer](../images/filters/panels/woman-singer-matte.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
