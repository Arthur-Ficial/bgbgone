# `colorize`

> monochrome at a target colour (CIColorMonochrome)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `colorize=color=#hex:amount=A` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:colorize=color=#0066ff:amount=0.5"
```

![`all:colorize=color=#0066ff:amount=0.5` on red-panda](../images/filters/colorize.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:colorize=color=#0066ff:amount=0.5"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:colorize=color=#0066ff:amount=0.5"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:colorize=color=#0066ff:amount=0.5"
```

![`colorize` panels on yoga](../images/filters/panels/yoga-colorize.jpg)
![`colorize` panels on woman-singer](../images/filters/panels/woman-singer-colorize.jpg)

See the [filter index](README.md) for the full catalogue.
