# `colorize`

> monochrome at a target colour (CIColorMonochrome)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `colorize=color=#hex:amount=A` |


## Example — red-panda, `fg:colorize=color=#0066ff:amount=0.5` (subject filter, background preserved)

The same operation through both transports. `scripts/gen-docs.sh` executes BOTH commands on every regen and asserts the outputs are byte-identical (parity contract). The image below is the result.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:colorize=color=#0066ff:amount=0.5" --size preview -o red-panda-colorize.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:colorize=color=#0066ff:amount=0.5" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-colorize.jpg
```

![red-panda after `fg:colorize=color=#0066ff:amount=0.5` — CLI render = server render (byte-identical)](../images/filters/colorize.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:colorize=color=#00bfff:amount=0.9"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:colorize=color=#00bfff:amount=0.9"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:colorize=color=#00bfff:amount=0.9"
```

Panels (`original | bg | fg | all`):

![`colorize` panels on yoga](../images/filters/panels/yoga-colorize.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:colorize=color=#00bfff:amount=0.9"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:colorize=color=#00bfff:amount=0.9"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:colorize=color=#00bfff:amount=0.9"
```

Panels (`original | bg | fg | all`):

![`colorize` panels on woman-singer](../images/filters/panels/woman-singer-colorize.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
