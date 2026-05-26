# `sharpen`

> luminance sharpen (CISharpenLuminance)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `sharpen=amount` |


## Example — red-panda, `fg:sharpen=0.5` (subject filter, background preserved)

The same operation through both transports. `scripts/gen-docs.sh` executes BOTH commands on every regen and asserts the outputs are byte-identical (parity contract). The image below is the result.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:sharpen=0.5" --size preview -o red-panda-sharpen.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:sharpen=0.5" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-sharpen.jpg
```

![red-panda after `fg:sharpen=0.5` — CLI render = server render (byte-identical)](../images/filters/sharpen.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:sharpen"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:sharpen"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:sharpen"
```

Panels (`original | bg | fg | all`):

![`sharpen` panels on yoga](../images/filters/panels/yoga-sharpen.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:sharpen"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:sharpen"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:sharpen"
```

Panels (`original | bg | fg | all`):

![`sharpen` panels on woman-singer](../images/filters/panels/woman-singer-sharpen.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
