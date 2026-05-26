# `sepia`

> warm-tinted monochrome 0..1 (CISepiaTone)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `sepia=intensity` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:sepia=0.8"
```

![`all:sepia=0.8` on red-panda](../images/filters/sepia.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:sepia=0.8"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:sepia=0.8"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:sepia=0.8"
```

![`sepia` panels on yoga](../images/filters/panels/yoga-sepia.jpg)
![`sepia` panels on woman-singer](../images/filters/panels/woman-singer-sepia.jpg)

See the [filter index](README.md) for the full catalogue.
