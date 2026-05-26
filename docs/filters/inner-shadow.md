# `inner-shadow`

> shadow inside the matte (invert+blur+intersect+tint)

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `inner-shadow=blur=B:offset=X,Y:opacity=O:color=#hex` |


## Example — red-panda, `fg:inner-shadow=blur=12:offset=4,4:opacity=0.5:color=#000` (subject filter, background preserved)

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:inner-shadow=blur=12:offset=4,4:opacity=0.5:color=#000" -o red-panda-inner-shadow.jpg
```

### Via HTTP server (`bgbgone --server`)

Same operation, same output (parity verified in `Tests/integration/run-server-parity.sh`):

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:inner-shadow=blur=12:offset=4,4:opacity=0.5:color=#000" \
  -F "format=jpg" \
  -o red-panda-inner-shadow.jpg
```

![red-panda after `fg:inner-shadow=blur=12:offset=4,4:opacity=0.5:color=#000`](../images/filters/inner-shadow.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:inner-shadow"
```

Panels (`original | bg | fg | all`):

![`inner-shadow` panels on yoga](../images/filters/panels/yoga-inner-shadow.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:inner-shadow"
```

Panels (`original | bg | fg | all`):

![`inner-shadow` panels on woman-singer](../images/filters/panels/woman-singer-inner-shadow.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
