# `gloom`

> dark-glow inverse of bloom, composite only (CIGloom)

| Field | Value |
|---|---|
| **Layers** | composite |
| **Signature** | `gloom=intensity:radius` |


## Example — red-panda, `composite:gloom=intensity=0.5:radius=10` (subject filter, background preserved)

The same operation through both transports. `scripts/gen-docs.sh` executes BOTH commands on every regen and asserts the outputs are byte-identical (parity contract). The image below is the result.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "composite:gloom=intensity=0.5:radius=10" --size preview -o red-panda-gloom.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=composite:gloom=intensity=0.5:radius=10" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-gloom.jpg
```

![red-panda after `composite:gloom=intensity=0.5:radius=10` — CLI render = server render (byte-identical)](../images/filters/gloom.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "composite:gloom"
```

Panels (`original | bg | fg | all`):

![`gloom` panels on yoga](../images/filters/panels/yoga-gloom.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "composite:gloom"
```

Panels (`original | bg | fg | all`):

![`gloom` panels on woman-singer](../images/filters/panels/woman-singer-gloom.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
