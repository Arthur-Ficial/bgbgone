# `grayscale`

> remove all colour saturation (CIColorControls)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `grayscale` |


## Example — red-panda, `fg:grayscale` (subject filter, background preserved)

The same operation through both transports. `scripts/gen-docs.sh` executes BOTH commands on every regen and asserts the outputs are byte-identical (parity contract). The image below is the result.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:grayscale" --size preview -o red-panda-grayscale.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:grayscale" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-grayscale.jpg
```

![red-panda after `fg:grayscale` — CLI render = server render (byte-identical)](../images/filters/grayscale.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:grayscale"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:grayscale"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:grayscale"
```

Panels (`original | bg | fg | all`):

![`grayscale` panels on yoga](../images/filters/panels/yoga-grayscale.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:grayscale"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:grayscale"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:grayscale"
```

Panels (`original | bg | fg | all`):

![`grayscale` panels on woman-singer](../images/filters/panels/woman-singer-grayscale.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
