# `negate`

> invert RGB (CIColorInvert)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `negate` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:negate"
```

![`all:negate` on red-panda](../images/filters/negate.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:negate"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:negate"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:negate"
```

![`negate` panels on yoga](../images/filters/panels/yoga-negate.jpg)
![`negate` panels on woman-singer](../images/filters/panels/woman-singer-negate.jpg)

See the [filter index](README.md) for the full catalogue.
