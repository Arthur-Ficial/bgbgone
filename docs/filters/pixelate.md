# `pixelate`

> block pixelation (CIPixellate)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `pixelate=size` |


## Example — red-panda, `fg:pixelate=20` (subject filter, background preserved)

The same operation through both transports. `scripts/gen-docs.sh` executes BOTH commands on every regen and asserts the outputs are byte-identical (parity contract). The image below is the result.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:pixelate=20" --size preview -o red-panda-pixelate.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:pixelate=20" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-pixelate.jpg
```

![red-panda after `fg:pixelate=20` — CLI render = server render (byte-identical)](../images/filters/pixelate.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:pixelate"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:pixelate"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:pixelate"
```

Panels (`original | bg | fg | all`):

![`pixelate` panels on yoga](../images/filters/panels/yoga-pixelate.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:pixelate"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:pixelate"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:pixelate"
```

Panels (`original | bg | fg | all`):

![`pixelate` panels on woman-singer](../images/filters/panels/woman-singer-pixelate.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
