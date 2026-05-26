# `posterize`

> quantise to N colour levels (CIColorPosterize)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `posterize=levels` |


## Example — red-panda, `fg:posterize=4` (subject filter, background preserved)

The same operation through both transports. `scripts/gen-docs.sh` executes BOTH commands on every regen and asserts the outputs are byte-identical (parity contract). The image below is the result.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:posterize=4" --size preview -o red-panda-posterize.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:posterize=4" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-posterize.jpg
```

![red-panda after `fg:posterize=4` — CLI render = server render (byte-identical)](../images/filters/posterize.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:posterize=4"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:posterize=4"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:posterize=4"
```

Panels (`original | bg | fg | all`):

![`posterize` panels on yoga](../images/filters/panels/yoga-posterize.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:posterize=4"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:posterize=4"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:posterize=4"
```

Panels (`original | bg | fg | all`):

![`posterize` panels on woman-singer](../images/filters/panels/woman-singer-posterize.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
