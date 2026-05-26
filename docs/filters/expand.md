# `expand`

> grow matte dilation (CIMorphologyMaximum)

| Field | Value |
|---|---|
| **Layers** | mask |
| **Signature** | `expand=pixels` |


## Example — red-panda, `mask:expand=3` (subject filter, background preserved)

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "mask:expand=3" -o red-panda-expand.jpg
```

### Via HTTP server (`bgbgone --server`)

Same operation, same output (parity verified in `Tests/integration/run-server-parity.sh`):

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=mask:expand=3" \
  -F "format=jpg" \
  -o red-panda-expand.jpg
```

![red-panda after `mask:expand=3`](../images/filters/expand.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "mask:expand"
```

Panels (`original | bg | fg | all`):

![`expand` panels on yoga](../images/filters/panels/yoga-expand.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "mask:expand"
```

Panels (`original | bg | fg | all`):

![`expand` panels on woman-singer](../images/filters/panels/woman-singer-expand.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
