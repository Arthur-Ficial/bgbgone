# `noise`

> additive film grain (CIRandomGenerator + composite)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `noise=amount` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:noise=0.1"
```

![`all:noise=0.1` on red-panda](../images/filters/noise.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:noise=0.1"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:noise=0.1"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:noise=0.1"
```

![`noise` panels on yoga](../images/filters/panels/yoga-noise.jpg)
![`noise` panels on woman-singer](../images/filters/panels/woman-singer-noise.jpg)

See the [filter index](README.md) for the full catalogue.
