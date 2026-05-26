# `box-blur`

> box (mean) blur (CIBoxBlur)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `box-blur=radius` |


## Example — red-panda, `fg:box-blur=15` (subject filter, background preserved)

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:box-blur=15" -o red-panda-box-blur.jpg
```

### Via HTTP server (`bgbgone --server`)

Same operation, same output (parity verified in `Tests/integration/run-server-parity.sh`):

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:box-blur=15" \
  -F "format=jpg" \
  -o red-panda-box-blur.jpg
```

![red-panda after `fg:box-blur=15`](../images/filters/box-blur.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:box-blur"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:box-blur"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:box-blur"
```

Panels (`original | bg | fg | all`):

![`box-blur` panels on yoga](../images/filters/panels/yoga-box-blur.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:box-blur"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:box-blur"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:box-blur"
```

Panels (`original | bg | fg | all`):

![`box-blur` panels on woman-singer](../images/filters/panels/woman-singer-box-blur.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
