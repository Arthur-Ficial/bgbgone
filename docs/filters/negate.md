# `negate`

> invert RGB (CIColorInvert)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `negate` |


## Example — red-panda, `fg:negate` (subject filter, background preserved)

The same operation through both transports. `scripts/gen-docs.sh` executes BOTH commands on every regen and asserts the outputs are byte-identical (parity contract). The image below is the result.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:negate" --size preview -o red-panda-negate.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:negate" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-negate.jpg
```

![red-panda after `fg:negate` — CLI render = server render (byte-identical)](../images/filters/negate.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:negate"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:negate"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:negate"
```

Panels (`original | bg | fg | all`):

![`negate` panels on yoga](../images/filters/panels/yoga-negate.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:negate"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:negate"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:negate"
```

Panels (`original | bg | fg | all`):

![`negate` panels on woman-singer](../images/filters/panels/woman-singer-negate.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
