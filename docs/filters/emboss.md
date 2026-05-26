# `emboss`

> raised relief via 3x3 convolution

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `emboss` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:emboss"
```

![`all:emboss` on red-panda](../images/filters/emboss.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:emboss"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:emboss"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:emboss"
```

![`emboss` panels on yoga](../images/filters/panels/yoga-emboss.jpg)
![`emboss` panels on woman-singer](../images/filters/panels/woman-singer-emboss.jpg)

See the [filter index](README.md) for the full catalogue.
