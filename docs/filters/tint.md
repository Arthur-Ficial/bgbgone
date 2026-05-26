# `tint`

> blend toward a tint colour (CIColorMonochrome)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `tint=color=#hex:amount=A` |


## Example — red-panda, `fg:tint=color=#0066ff:amount=0.5` (subject filter, background preserved)

The same operation through both transports. `scripts/gen-docs.sh` executes BOTH commands on every regen and asserts the outputs are byte-identical (parity contract). The image below is the result.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:tint=color=#0066ff:amount=0.5" --size preview -o red-panda-tint.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:tint=color=#0066ff:amount=0.5" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-tint.jpg
```

![red-panda after `fg:tint=color=#0066ff:amount=0.5` — CLI render = server render (byte-identical)](../images/filters/tint.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:tint"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:tint"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:tint"
```

Panels (`original | bg | fg | all`):

![`tint` panels on yoga](../images/filters/panels/yoga-tint.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:tint"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:tint"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:tint"
```

Panels (`original | bg | fg | all`):

![`tint` panels on woman-singer](../images/filters/panels/woman-singer-tint.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
