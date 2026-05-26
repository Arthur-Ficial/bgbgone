# `desaturate`

> scale saturation by 1-amount (CIColorControls)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `desaturate=amount` |


## Example — red-panda, `fg:desaturate=0.5` (subject filter, background preserved)

The same operation through both transports. `scripts/gen-docs.sh` executes BOTH commands on every regen and asserts the outputs are byte-identical (parity contract). The image below is the result.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:desaturate=0.5" --size preview -o red-panda-desaturate.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:desaturate=0.5" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-desaturate.jpg
```

![red-panda after `fg:desaturate=0.5` — CLI render = server render (byte-identical)](../images/filters/desaturate.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:desaturate=0.8"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:desaturate=0.8"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:desaturate=0.8"
```

Panels (`original | bg | fg | all`):

![`desaturate` panels on yoga](../images/filters/panels/yoga-desaturate.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:desaturate=0.8"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:desaturate=0.8"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:desaturate=0.8"
```

Panels (`original | bg | fg | all`):

![`desaturate` panels on woman-singer](../images/filters/panels/woman-singer-desaturate.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
