# `pointillize`

> Seurat dot effect (CIPointillize)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `pointillize=radius` |


## Example — `fg:pointillize=5`

The same operation through both transports. `scripts/gen-docs.sh` runs BOTH commands on every regen and asserts byte-identical output (parity contract). The result is shown below.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:pointillize=5" --size preview -o red-panda-pointillize.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:pointillize=5" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-pointillize.jpg
```

![red-panda after `fg:pointillize=5` — CLI render = server render (byte-identical)](../images/filters/pointillize.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:pointillize=15"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:pointillize=15"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:pointillize=15"
```

Panels (`original | bg | fg | all`):

![`pointillize` panels on yoga](../images/filters/panels/yoga-pointillize.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:pointillize=15"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:pointillize=15"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:pointillize=15"
```

Panels (`original | bg | fg | all`):

![`pointillize` panels on woman-singer](../images/filters/panels/woman-singer-pointillize.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
