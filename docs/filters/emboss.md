# `emboss`

> raised relief via 3x3 convolution

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `emboss` |


## Example — red-panda, `fg:emboss` (subject filter, background preserved)

The same operation through both transports. `scripts/gen-docs.sh` executes BOTH commands on every regen and asserts the outputs are byte-identical (parity contract). The image below is the result.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:emboss" --size preview -o red-panda-emboss.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:emboss" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-emboss.jpg
```

![red-panda after `fg:emboss` — CLI render = server render (byte-identical)](../images/filters/emboss.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:emboss"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:emboss"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:emboss"
```

Panels (`original | bg | fg | all`):

![`emboss` panels on yoga](../images/filters/panels/yoga-emboss.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:emboss"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:emboss"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:emboss"
```

Panels (`original | bg | fg | all`):

![`emboss` panels on woman-singer](../images/filters/panels/woman-singer-emboss.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
