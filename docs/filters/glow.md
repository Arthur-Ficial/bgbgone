# `glow`

> subject glow halo (blur+tint+composite)

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `glow=color=#hex:radius=R:intensity=I` |
| **Note** | introduces alpha — output here is JPEG over the source bg; use `-o out.png` for true transparent output |

## Example — red-panda, `fg:glow=color=#ffe080:radius=10:intensity=0.6` (subject filter, background preserved)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:glow=color=#ffe080:radius=10:intensity=0.6" -o red-panda-glow.jpg
```

![red-panda after `fg:glow=color=#ffe080:radius=10:intensity=0.6`](../images/filters/glow.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:glow"
```

Panels (`original | bg | fg | all`):

![`glow` panels on yoga](../images/filters/panels/yoga-glow.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:glow"
```

Panels (`original | bg | fg | all`):

![`glow` panels on woman-singer](../images/filters/panels/woman-singer-glow.jpg)

See the [filter index](README.md) for the full catalogue.
