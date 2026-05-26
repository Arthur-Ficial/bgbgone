# `adjust`

> brightness/contrast/saturation in one call (CIColorControls)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `adjust=brightness=B:contrast=C:saturation=S` |


## Example — red-panda, `fg:adjust=brightness=0.1:contrast=1.1:saturation=0.9` (subject filter, background preserved)

The same operation through both transports. `scripts/gen-docs.sh` executes BOTH commands on every regen and asserts the outputs are byte-identical (parity contract). The image below is the result.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:adjust=brightness=0.1:contrast=1.1:saturation=0.9" --size preview -o red-panda-adjust.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:adjust=brightness=0.1:contrast=1.1:saturation=0.9" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-adjust.jpg
```

![red-panda after `fg:adjust=brightness=0.1:contrast=1.1:saturation=0.9` — CLI render = server render (byte-identical)](../images/filters/adjust.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:adjust"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:adjust"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:adjust"
```

Panels (`original | bg | fg | all`):

![`adjust` panels on yoga](../images/filters/panels/yoga-adjust.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:adjust"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:adjust"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:adjust"
```

Panels (`original | bg | fg | all`):

![`adjust` panels on woman-singer](../images/filters/panels/woman-singer-adjust.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
