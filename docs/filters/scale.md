# `scale`

> scale subject around centre (CIAffineTransform)

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `scale=factor` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:scale=0.75"
```

![`fg:scale=0.75` on red-panda](../images/filters/scale.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:scale=0.75"
```

![`scale` panels on yoga](../images/filters/panels/yoga-scale.jpg)
![`scale` panels on woman-singer](../images/filters/panels/woman-singer-scale.jpg)

See the [filter index](README.md) for the full catalogue.
