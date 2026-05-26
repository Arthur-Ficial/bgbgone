# `sepia`

> warm-tinted monochrome 0..1 (CISepiaTone)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `sepia=intensity` |


## Example — red-panda, `fg:sepia=0.8` (subject filter, background preserved)

The same operation through both transports. `scripts/gen-docs.sh` executes BOTH commands on every regen and asserts the outputs are byte-identical (parity contract). The image below is the result.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:sepia=0.8" --size preview -o red-panda-sepia.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:sepia=0.8" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-sepia.jpg
```

![red-panda after `fg:sepia=0.8` — CLI render = server render (byte-identical)](../images/filters/sepia.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:sepia"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:sepia"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:sepia"
```

Panels (`original | bg | fg | all`):

![`sepia` panels on yoga](../images/filters/panels/yoga-sepia.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:sepia"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:sepia"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:sepia"
```

Panels (`original | bg | fg | all`):

![`sepia` panels on woman-singer](../images/filters/panels/woman-singer-sepia.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
