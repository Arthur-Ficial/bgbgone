# `gamma`

> gamma curve, typical 0.5..2.5 (CIGammaAdjust)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `gamma=value` |


## Example — red-panda, `fg:gamma=1.2` (subject filter, background preserved)

The same operation through both transports. `scripts/gen-docs.sh` executes BOTH commands on every regen and asserts the outputs are byte-identical (parity contract). The image below is the result.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:gamma=1.2" --size preview -o red-panda-gamma.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:gamma=1.2" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-gamma.jpg
```

![red-panda after `fg:gamma=1.2` — CLI render = server render (byte-identical)](../images/filters/gamma.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:gamma"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:gamma"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:gamma"
```

Panels (`original | bg | fg | all`):

![`gamma` panels on yoga](../images/filters/panels/yoga-gamma.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:gamma"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:gamma"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:gamma"
```

Panels (`original | bg | fg | all`):

![`gamma` panels on woman-singer](../images/filters/panels/woman-singer-gamma.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
