# `vibrance`

> boost low-saturation colours (CIVibrance)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `vibrance=amount` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:vibrance=0.5"
```

![`all:vibrance=0.5` on red-panda](../images/filters/vibrance.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:vibrance=0.5"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:vibrance=0.5"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:vibrance=0.5"
```

![`vibrance` panels on yoga](../images/filters/panels/yoga-vibrance.jpg)
![`vibrance` panels on woman-singer](../images/filters/panels/woman-singer-vibrance.jpg)

See the [filter index](README.md) for the full catalogue.
