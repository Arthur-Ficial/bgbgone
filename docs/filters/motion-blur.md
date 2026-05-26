# `motion-blur`

> directional blur (CIMotionBlur)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `motion-blur=radius:angle` |


## Example — red-panda, `fg:motion-blur=radius=10:angle=45` (subject filter, background preserved)

The same operation through both transports. `scripts/gen-docs.sh` executes BOTH commands on every regen and asserts the outputs are byte-identical (parity contract). The image below is the result.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:motion-blur=radius=10:angle=45" --size preview -o red-panda-motion-blur.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:motion-blur=radius=10:angle=45" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-motion-blur.jpg
```

![red-panda after `fg:motion-blur=radius=10:angle=45` — CLI render = server render (byte-identical)](../images/filters/motion-blur.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:motion-blur"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:motion-blur"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:motion-blur"
```

Panels (`original | bg | fg | all`):

![`motion-blur` panels on yoga](../images/filters/panels/yoga-motion-blur.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:motion-blur"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:motion-blur"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:motion-blur"
```

Panels (`original | bg | fg | all`):

![`motion-blur` panels on woman-singer](../images/filters/panels/woman-singer-motion-blur.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
