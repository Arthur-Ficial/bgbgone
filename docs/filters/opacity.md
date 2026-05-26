# `opacity`

> scale alpha by value 0..1 (CIColorMatrix)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `opacity=value` |
| **Note** | introduces alpha — use PNG output or pass `--bg` |

## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:opacity=0.7"
```

![`all:opacity=0.7` on red-panda](../images/filters/opacity.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:opacity=0.7"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:opacity=0.7"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:opacity=0.7"
```

![`opacity` panels on yoga](../images/filters/panels/yoga-opacity.jpg)
![`opacity` panels on woman-singer](../images/filters/panels/woman-singer-opacity.jpg)

See the [filter index](README.md) for the full catalogue.
