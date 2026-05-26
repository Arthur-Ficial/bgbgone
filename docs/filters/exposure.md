# `exposure`

> +/- stops, typical -2..+2 (CIExposureAdjust)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `exposure=stops` |


## Example — red-panda, `fg:exposure=1.0` (subject filter, background preserved)

The same operation through both transports. `scripts/gen-docs.sh` executes BOTH commands on every regen and asserts the outputs are byte-identical (parity contract). The image below is the result.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:exposure=1.0" --size preview -o red-panda-exposure.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:exposure=1.0" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-exposure.jpg
```

![red-panda after `fg:exposure=1.0` — CLI render = server render (byte-identical)](../images/filters/exposure.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:exposure"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:exposure"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:exposure"
```

Panels (`original | bg | fg | all`):

![`exposure` panels on yoga](../images/filters/panels/yoga-exposure.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:exposure"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:exposure"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:exposure"
```

Panels (`original | bg | fg | all`):

![`exposure` panels on woman-singer](../images/filters/panels/woman-singer-exposure.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
