# `box-blur`

> box (mean) blur (CIBoxBlur)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `box-blur=radius` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:box-blur=15"
```

![`all:box-blur=15` on red-panda](../images/filters/box-blur.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:box-blur=15"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:box-blur=15"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:box-blur=15"
```

![`box-blur` panels on yoga](../images/filters/panels/yoga-box-blur.jpg)
![`box-blur` panels on woman-singer](../images/filters/panels/woman-singer-box-blur.jpg)

See the [filter index](README.md) for the full catalogue.
