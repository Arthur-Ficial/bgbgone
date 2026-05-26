# `bloom`

> soft glow on highlights, composite only (CIBloom)

| Field | Value |
|---|---|
| **Layers** | composite |
| **Signature** | `bloom=intensity:radius` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "composite:bloom=intensity=0.5:radius=10"
```

![`composite:bloom=intensity=0.5:radius=10` on red-panda](../images/filters/bloom.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg color:#1a2233 --filter "composite:bloom=intensity=0.5:radius=10"
```

![`bloom` panels on yoga](../images/filters/panels/yoga-bloom.jpg)
![`bloom` panels on woman-singer](../images/filters/panels/woman-singer-bloom.jpg)

See the [filter index](README.md) for the full catalogue.
