# `grayscale`

> remove all colour saturation (CIColorControls)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `grayscale` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:grayscale"
```

![`all:grayscale` on red-panda](../images/filters/grayscale.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:grayscale"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:grayscale"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:grayscale"
```

![`grayscale` panels on yoga](../images/filters/panels/yoga-grayscale.jpg)
![`grayscale` panels on woman-singer](../images/filters/panels/woman-singer-grayscale.jpg)

See the [filter index](README.md) for the full catalogue.
