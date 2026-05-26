# `blur`

> Gaussian blur, radius in px (CIGaussianBlur)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `blur=radius` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:blur=15"
```

![`all:blur=15` on red-panda](../images/filters/blur.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:blur=15"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:blur=15"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:blur=15"
```

![`blur` panels on yoga](../images/filters/panels/yoga-blur.jpg)
![`blur` panels on woman-singer](../images/filters/panels/woman-singer-blur.jpg)

See the [filter index](README.md) for the full catalogue.
