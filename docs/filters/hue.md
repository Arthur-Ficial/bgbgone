# `hue`

> rotate hue by N degrees (CIHueAdjust)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `hue=degrees` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:hue=120"
```

![`all:hue=120` on red-panda](../images/filters/hue.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:hue=120"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:hue=120"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:hue=120"
```

![`hue` panels on yoga](../images/filters/panels/yoga-hue.jpg)
![`hue` panels on woman-singer](../images/filters/panels/woman-singer-hue.jpg)

See the [filter index](README.md) for the full catalogue.
