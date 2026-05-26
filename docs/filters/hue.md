# `hue`

> rotate hue by N degrees (CIHueAdjust)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `hue=degrees` |


## Example — red-panda, `fg:hue=120` (subject filter, background preserved)

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:hue=120" -o red-panda-hue.jpg
```

### Via HTTP server (`bgbgone --server`)

Same operation, same output (parity verified in `Tests/integration/run-server-parity.sh`):

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:hue=120" \
  -F "format=jpg" \
  -o red-panda-hue.jpg
```

![red-panda after `fg:hue=120`](../images/filters/hue.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:hue"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:hue"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:hue"
```

Panels (`original | bg | fg | all`):

![`hue` panels on yoga](../images/filters/panels/yoga-hue.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:hue"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:hue"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:hue"
```

Panels (`original | bg | fg | all`):

![`hue` panels on woman-singer](../images/filters/panels/woman-singer-hue.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
