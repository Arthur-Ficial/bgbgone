# `vibrance`

> boost low-saturation colours (CIVibrance)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `vibrance=amount` |


## Example — red-panda, `fg:vibrance=0.5` (subject filter, background preserved)

The same operation through both transports. `scripts/gen-docs.sh` executes BOTH commands on every regen and asserts the outputs are byte-identical (parity contract). The image below is the result.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:vibrance=0.5" --size preview -o red-panda-vibrance.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:vibrance=0.5" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-vibrance.jpg
```

![red-panda after `fg:vibrance=0.5` — CLI render = server render (byte-identical)](../images/filters/vibrance.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:vibrance"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:vibrance"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:vibrance"
```

Panels (`original | bg | fg | all`):

![`vibrance` panels on yoga](../images/filters/panels/yoga-vibrance.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:vibrance"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:vibrance"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:vibrance"
```

Panels (`original | bg | fg | all`):

![`vibrance` panels on woman-singer](../images/filters/panels/woman-singer-vibrance.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
