# `adjust`

> brightness/contrast/saturation in one call (CIColorControls)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `adjust=brightness=B:contrast=C:saturation=S` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:adjust=brightness=0.1:contrast=1.1:saturation=0.9"
```

![`all:adjust=brightness=0.1:contrast=1.1:saturation=0.9` on red-panda](../images/filters/adjust.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:adjust=brightness=0.1:contrast=1.1:saturation=0.9"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:adjust=brightness=0.1:contrast=1.1:saturation=0.9"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:adjust=brightness=0.1:contrast=1.1:saturation=0.9"
```

![`adjust` panels on yoga](../images/filters/panels/yoga-adjust.jpg)
![`adjust` panels on woman-singer](../images/filters/panels/woman-singer-adjust.jpg)

See the [filter index](README.md) for the full catalogue.
