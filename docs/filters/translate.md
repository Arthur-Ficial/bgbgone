# `translate`

> shift subject in pixels (CIAffineTransform)

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `translate=dx,dy` |


## Example — red-panda, `fg:translate=-200,200` (subject filter, background preserved)

The same operation through both transports. `scripts/gen-docs.sh` executes BOTH commands on every regen and asserts the outputs are byte-identical (parity contract). The image below is the result.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:translate=-200,200" --size preview -o red-panda-translate.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:translate=-200,200" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-translate.jpg
```

![red-panda after `fg:translate=-200,200` — CLI render = server render (byte-identical)](../images/filters/translate.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:translate"
```

Panels (`original | bg | fg | all`):

![`translate` panels on yoga](../images/filters/panels/yoga-translate.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:translate"
```

Panels (`original | bg | fg | all`):

![`translate` panels on woman-singer](../images/filters/panels/woman-singer-translate.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
