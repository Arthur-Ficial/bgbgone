# `vignette-effect`

> positioned vignette, composite only (CIVignetteEffect)

| Field | Value |
|---|---|
| **Layers** | composite |
| **Signature** | `vignette-effect=center=X,Y:radius=R:intensity=I` |


## Example — red-panda, `composite:vignette-effect=center=0.5,0.5:radius=1.5:intensity=1` (subject filter, background preserved)

The same operation through both transports. `scripts/gen-docs.sh` executes BOTH commands on every regen and asserts the outputs are byte-identical (parity contract). The image below is the result.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "composite:vignette-effect=center=0.5,0.5:radius=1.5:intensity=1" --size preview -o red-panda-vignette-effect.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=composite:vignette-effect=center=0.5,0.5:radius=1.5:intensity=1" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-vignette-effect.jpg
```

![red-panda after `composite:vignette-effect=center=0.5,0.5:radius=1.5:intensity=1` — CLI render = server render (byte-identical)](../images/filters/vignette-effect.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "composite:vignette-effect"
```

Panels (`original | bg | fg | all`):

![`vignette-effect` panels on yoga](../images/filters/panels/yoga-vignette-effect.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "composite:vignette-effect"
```

Panels (`original | bg | fg | all`):

![`vignette-effect` panels on woman-singer](../images/filters/panels/woman-singer-vignette-effect.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
