# `duotone`

> two-colour map by luminance (CIColorMatrix)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `duotone=dark=#hex:light=#hex` |


## Example — red-panda, `fg:duotone=dark=#003366:light=#ffcc00` (subject filter, background preserved)

The same operation through both transports. `scripts/gen-docs.sh` executes BOTH commands on every regen and asserts the outputs are byte-identical (parity contract). The image below is the result.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:duotone=dark=#003366:light=#ffcc00" --size preview -o red-panda-duotone.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:duotone=dark=#003366:light=#ffcc00" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-duotone.jpg
```

![red-panda after `fg:duotone=dark=#003366:light=#ffcc00` — CLI render = server render (byte-identical)](../images/filters/duotone.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:duotone=dark=#003366:light=#ffcc00"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:duotone=dark=#003366:light=#ffcc00"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:duotone=dark=#003366:light=#ffcc00"
```

Panels (`original | bg | fg | all`):

![`duotone` panels on yoga](../images/filters/panels/yoga-duotone.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:duotone=dark=#003366:light=#ffcc00"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:duotone=dark=#003366:light=#ffcc00"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:duotone=dark=#003366:light=#ffcc00"
```

Panels (`original | bg | fg | all`):

![`duotone` panels on woman-singer](../images/filters/panels/woman-singer-duotone.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
