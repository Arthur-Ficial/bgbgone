# `edges`

> edge detection (CIEdges)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `edges=intensity` |


## Example — `fg:edges=2.5`

The same operation through both transports. `scripts/gen-docs.sh` runs BOTH commands on every regen and asserts byte-identical output (parity contract). The result is shown below.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:edges=2.5" --size preview -o red-panda-edges.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:edges=2.5" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-edges.jpg
```

![red-panda after `fg:edges=2.5` — CLI render = server render (byte-identical)](../images/filters/edges.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:edges=2.5"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:edges=2.5"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:edges=2.5"
```

Panels (`original | bg | fg | all`):

![`edges` panels on yoga](../images/filters/panels/yoga-edges.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:edges=2.5"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:edges=2.5"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:edges=2.5"
```

Panels (`original | bg | fg | all`):

![`edges` panels on woman-singer](../images/filters/panels/woman-singer-edges.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
