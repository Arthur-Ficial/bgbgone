# `crystallize`

> Voronoi mosaic (CICrystallize)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `crystallize=radius` |


## Example — `fg:crystallize=20`

The same operation through both transports. `scripts/gen-docs.sh` runs BOTH commands on every regen and asserts byte-identical output (parity contract). The result is shown below.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:crystallize=20" --size preview -o red-panda-crystallize.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:crystallize=20" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-crystallize.jpg
```

![red-panda after `fg:crystallize=20` — CLI render = server render (byte-identical)](../images/filters/crystallize.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:crystallize=30"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:crystallize=30"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:crystallize=30"
```

Panels (`original | bg | fg | all`):

![`crystallize` panels on yoga](../images/filters/panels/yoga-crystallize.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:crystallize=30"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:crystallize=30"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:crystallize=30"
```

Panels (`original | bg | fg | all`):

![`crystallize` panels on woman-singer](../images/filters/panels/woman-singer-crystallize.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
