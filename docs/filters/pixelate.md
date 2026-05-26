# `pixelate`

> block pixelation (CIPixellate)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `pixelate=size` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:pixelate=20"
```

![`all:pixelate=20` on red-panda](../images/filters/pixelate.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:pixelate=20"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:pixelate=20"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:pixelate=20"
```

![`pixelate` panels on yoga](../images/filters/panels/yoga-pixelate.jpg)
![`pixelate` panels on woman-singer](../images/filters/panels/woman-singer-pixelate.jpg)

See the [filter index](README.md) for the full catalogue.
