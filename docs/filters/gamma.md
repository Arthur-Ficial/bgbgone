# `gamma`

> gamma curve, typical 0.5..2.5 (CIGammaAdjust)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `gamma=value` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:gamma=1.2"
```

![`all:gamma=1.2` on red-panda](../images/filters/gamma.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:gamma=1.2"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:gamma=1.2"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:gamma=1.2"
```

![`gamma` panels on yoga](../images/filters/panels/yoga-gamma.jpg)
![`gamma` panels on woman-singer](../images/filters/panels/woman-singer-gamma.jpg)

See the [filter index](README.md) for the full catalogue.
