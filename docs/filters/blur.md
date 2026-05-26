# `blur`

> Gaussian blur, radius in px (CIGaussianBlur)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `blur=radius` |


## Example — red-panda, `fg:blur=15` (subject filter, background preserved)

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:blur=15" -o red-panda-blur.jpg
```

### Via HTTP server (`bgbgone --server`)

Same operation, same output (parity verified in `Tests/integration/run-server-parity.sh`):

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:blur=15" \
  -F "format=jpg" \
  -o red-panda-blur.jpg
```

![red-panda after `fg:blur=15`](../images/filters/blur.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:blur"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:blur"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:blur"
```

Panels (`original | bg | fg | all`):

![`blur` panels on yoga](../images/filters/panels/yoga-blur.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:blur"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:blur"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:blur"
```

Panels (`original | bg | fg | all`):

![`blur` panels on woman-singer](../images/filters/panels/woman-singer-blur.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
