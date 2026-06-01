# `cutout`

> subject becomes a hole; background stays

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `cutout` |
| **Note** | introduces alpha — output here is JPEG over the source bg; use `-o out.png` for true transparent output |

## Example — `fg:cutout`

The same operation through both transports. `scripts/gen-docs.sh` runs BOTH commands on every regen and asserts byte-identical output (parity contract). The result is shown below.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:cutout" --size preview -o red-panda-cutout.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:cutout" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-cutout.jpg
```

![red-panda after `fg:cutout` — CLI render = server render (byte-identical)](../images/filters/cutout.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:cutout"
```

Panels (`original | bg | fg | all`):

![`cutout` panels on yoga](../images/filters/panels/yoga-cutout.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:cutout"
```

Panels (`original | bg | fg | all`):

![`cutout` panels on woman-singer](../images/filters/panels/woman-singer-cutout.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
