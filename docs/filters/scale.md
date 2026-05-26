# `scale`

> scale subject around centre (CIAffineTransform)

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `scale=factor` |


## Example — red-panda, `fg:scale=0.75` (subject filter, background preserved)

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:scale=0.75" -o red-panda-scale.jpg
```

### Via HTTP server (`bgbgone --server`)

Same operation, same output (parity verified in `Tests/integration/run-server-parity.sh`):

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:scale=0.75" \
  -F "format=jpg" \
  -o red-panda-scale.jpg
```

![red-panda after `fg:scale=0.75`](../images/filters/scale.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:scale"
```

Panels (`original | bg | fg | all`):

![`scale` panels on yoga](../images/filters/panels/yoga-scale.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:scale"
```

Panels (`original | bg | fg | all`):

![`scale` panels on woman-singer](../images/filters/panels/woman-singer-scale.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
