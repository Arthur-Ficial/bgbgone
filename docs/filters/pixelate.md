# `pixelate`

> block pixelation (CIPixellate)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `pixelate=size` |


## Example — `fg:pixelate=20`

The same operation through both transports. `scripts/gen-docs.sh` runs BOTH commands on every regen and asserts byte-identical output (parity contract). The result is shown below.

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
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:pixelate=25"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:pixelate=25"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:pixelate=25"
```

Panels (`original | bg | fg | all`):

![`pixelate` panels on yoga](../images/filters/panels/yoga-pixelate.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:pixelate=25"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:pixelate=25"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:pixelate=25"
```

Panels (`original | bg | fg | all`):

![`pixelate` panels on woman-singer](../images/filters/panels/woman-singer-pixelate.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
