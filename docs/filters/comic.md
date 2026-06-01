# `comic`

> halftone comic-book effect (CIComicEffect)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `comic` |


## Example — `fg:comic`

The same operation through both transports. `scripts/gen-docs.sh` runs BOTH commands on every regen and asserts byte-identical output (parity contract). The result is shown below.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:comic" --size preview -o red-panda-comic.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:comic" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-comic.jpg
```

![red-panda after `fg:comic` — CLI render = server render (byte-identical)](../images/filters/comic.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:comic"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:comic"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:comic"
```

Panels (`original | bg | fg | all`):

![`comic` panels on yoga](../images/filters/panels/yoga-comic.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:comic"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:comic"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:comic"
```

Panels (`original | bg | fg | all`):

![`comic` panels on woman-singer](../images/filters/panels/woman-singer-comic.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
