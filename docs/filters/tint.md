# `tint`

> blend toward a tint colour (CIColorMonochrome)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `tint=color=#hex:amount=A` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:tint=color=#0066ff:amount=0.5"
```

![`all:tint=color=#0066ff:amount=0.5` on red-panda](../images/filters/tint.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:tint=color=#0066ff:amount=0.5"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:tint=color=#0066ff:amount=0.5"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:tint=color=#0066ff:amount=0.5"
```

![`tint` panels on yoga](../images/filters/panels/yoga-tint.jpg)
![`tint` panels on woman-singer](../images/filters/panels/woman-singer-tint.jpg)

See the [filter index](README.md) for the full catalogue.
