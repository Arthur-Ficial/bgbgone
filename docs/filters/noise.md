# `noise`

> additive film grain (CIRandomGenerator + composite)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `noise=amount` |


## Example — `fg:noise=0.1`

The same operation through both transports. `scripts/gen-docs.sh` runs BOTH commands on every regen and asserts byte-identical output (parity contract). The result is shown below.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:noise=0.1" --size preview -o red-panda-noise.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:noise=0.1" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-noise.jpg
```

![red-panda after `fg:noise=0.1` — CLI render = server render (byte-identical)](../images/filters/noise.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:noise=0.3"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:noise=0.3"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:noise=0.3"
```

Panels (`original | bg | fg | all`):

![`noise` panels on yoga](../images/filters/panels/yoga-noise.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:noise=0.3"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:noise=0.3"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:noise=0.3"
```

Panels (`original | bg | fg | all`):

![`noise` panels on woman-singer](../images/filters/panels/woman-singer-noise.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
