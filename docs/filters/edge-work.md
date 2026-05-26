# `edge-work`

> line-art edges (CIEdgeWork)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `edge-work=radius` |


## Example — red-panda, `fg:edge-work=3` (subject filter, background preserved)

The same operation through both transports. `scripts/gen-docs.sh` executes BOTH commands on every regen and asserts the outputs are byte-identical (parity contract). The image below is the result.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:edge-work=3" --size preview -o red-panda-edge-work.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:edge-work=3" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-edge-work.jpg
```

![red-panda after `fg:edge-work=3` — CLI render = server render (byte-identical)](../images/filters/edge-work.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:edge-work=3"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:edge-work=3"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:edge-work=3"
```

Panels (`original | bg | fg | all`):

![`edge-work` panels on yoga](../images/filters/panels/yoga-edge-work.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:edge-work=3"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:edge-work=3"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:edge-work=3"
```

Panels (`original | bg | fg | all`):

![`edge-work` panels on woman-singer](../images/filters/panels/woman-singer-edge-work.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
