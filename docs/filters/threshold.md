# `threshold`

> binarise matte (CIColorThreshold)

| Field | Value |
|---|---|
| **Layers** | mask |
| **Signature** | `threshold=value` |


## Example — red-panda, `mask:threshold=0.5` (subject filter, background preserved)

The same operation through both transports. `scripts/gen-docs.sh` executes BOTH commands on every regen and asserts the outputs are byte-identical (parity contract). The image below is the result.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "mask:threshold=0.5" --size preview -o red-panda-threshold.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=mask:threshold=0.5" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-threshold.jpg
```

![red-panda after `mask:threshold=0.5` — CLI render = server render (byte-identical)](../images/filters/threshold.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "mask:threshold=0.5"
```

Panels (`original | bg | fg | all`):

![`threshold` panels on yoga](../images/filters/panels/yoga-threshold.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "mask:threshold=0.5"
```

Panels (`original | bg | fg | all`):

![`threshold` panels on woman-singer](../images/filters/panels/woman-singer-threshold.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
