# `feather`

> soften matte edge (CIGaussianBlur on mask)

| Field | Value |
|---|---|
| **Layers** | mask |
| **Signature** | `feather=radius` |


## Example — red-panda, `mask:feather=8` (subject filter, background preserved)

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "mask:feather=8" -o red-panda-feather.jpg
```

### Via HTTP server (`bgbgone --server`)

Same operation, same output (parity verified in `Tests/integration/run-server-parity.sh`):

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=mask:feather=8" \
  -F "format=jpg" \
  -o red-panda-feather.jpg
```

![red-panda after `mask:feather=8`](../images/filters/feather.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "mask:feather"
```

Panels (`original | bg | fg | all`):

![`feather` panels on yoga](../images/filters/panels/yoga-feather.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "mask:feather"
```

Panels (`original | bg | fg | all`):

![`feather` panels on woman-singer](../images/filters/panels/woman-singer-feather.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
