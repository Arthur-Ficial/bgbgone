# `gloom`

> dark-glow inverse of bloom, composite only (CIGloom)

| Field | Value |
|---|---|
| **Layers** | composite |
| **Signature** | `gloom=intensity:radius` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "composite:gloom=intensity=0.5:radius=10"
```

![`composite:gloom=intensity=0.5:radius=10` on red-panda](../images/filters/gloom.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg color:#1a2233 --filter "composite:gloom=intensity=0.5:radius=10"
```

![`gloom` panels on yoga](../images/filters/panels/yoga-gloom.jpg)
![`gloom` panels on woman-singer](../images/filters/panels/woman-singer-gloom.jpg)

See the [filter index](README.md) for the full catalogue.
