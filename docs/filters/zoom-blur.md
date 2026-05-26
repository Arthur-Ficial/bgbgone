# `zoom-blur`

> radial zoom blur (CIZoomBlur)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `zoom-blur=center=X,Y:amount=A` |


## Example — red-panda, `fg:zoom-blur=center=0.5,0.5:amount=20` (subject filter, background preserved)

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:zoom-blur=center=0.5,0.5:amount=20" -o red-panda-zoom-blur.jpg
```

### Via HTTP server (`bgbgone --server`)

Same operation, same output (parity verified in `Tests/integration/run-server-parity.sh`):

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:zoom-blur=center=0.5,0.5:amount=20" \
  -F "format=jpg" \
  -o red-panda-zoom-blur.jpg
```

![red-panda after `fg:zoom-blur=center=0.5,0.5:amount=20`](../images/filters/zoom-blur.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:zoom-blur"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:zoom-blur"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:zoom-blur"
```

Panels (`original | bg | fg | all`):

![`zoom-blur` panels on yoga](../images/filters/panels/yoga-zoom-blur.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:zoom-blur"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:zoom-blur"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:zoom-blur"
```

Panels (`original | bg | fg | all`):

![`zoom-blur` panels on woman-singer](../images/filters/panels/woman-singer-zoom-blur.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
