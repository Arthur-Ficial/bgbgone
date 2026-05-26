# `levels`

> Photoshop-style levels (CIColorMatrix + CIGammaAdjust)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `levels=black=B:white=W:gamma=G` |


## Example — red-panda, `fg:levels=black=20:white=235:gamma=1.0` (subject filter, background preserved)

The same operation through both transports. `scripts/gen-docs.sh` executes BOTH commands on every regen and asserts the outputs are byte-identical (parity contract). The image below is the result.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:levels=black=20:white=235:gamma=1.0" --size preview -o red-panda-levels.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:levels=black=20:white=235:gamma=1.0" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-levels.jpg
```

![red-panda after `fg:levels=black=20:white=235:gamma=1.0` — CLI render = server render (byte-identical)](../images/filters/levels.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:levels=black=0.1:white=0.9:gamma=1.2"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:levels=black=0.1:white=0.9:gamma=1.2"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:levels=black=0.1:white=0.9:gamma=1.2"
```

Panels (`original | bg | fg | all`):

![`levels` panels on yoga](../images/filters/panels/yoga-levels.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:levels=black=0.1:white=0.9:gamma=1.2"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:levels=black=0.1:white=0.9:gamma=1.2"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:levels=black=0.1:white=0.9:gamma=1.2"
```

Panels (`original | bg | fg | all`):

![`levels` panels on woman-singer](../images/filters/panels/woman-singer-levels.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
