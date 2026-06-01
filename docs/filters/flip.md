# `flip`

> mirror subject (CIAffineTransform)

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `flip=horizontal|vertical` |


## Example — `fg:flip=horizontal`

The same operation through both transports. `scripts/gen-docs.sh` runs BOTH commands on every regen and asserts byte-identical output (parity contract). The result is shown below.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:flip=horizontal" --size preview -o red-panda-flip.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:flip=horizontal" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-flip.jpg
```

![red-panda after `fg:flip=horizontal` — CLI render = server render (byte-identical)](../images/filters/flip.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:flip=horizontal"
```

Panels (`original | bg | fg | all`):

![`flip` panels on yoga](../images/filters/panels/yoga-flip.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:flip=horizontal"
```

Panels (`original | bg | fg | all`):

![`flip` panels on woman-singer](../images/filters/panels/woman-singer-flip.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
