# `feather`

> soften matte edge (CIGaussianBlur on mask)

| Field | Value |
|---|---|
| **Layers** | mask |
| **Signature** | `feather=radius` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "mask:feather=8"
```

![`mask:feather=8` on red-panda](../images/filters/feather.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg color:#1a2233 --filter "mask:feather=8"
```

![`feather` panels on yoga](../images/filters/panels/yoga-feather.jpg)
![`feather` panels on woman-singer](../images/filters/panels/woman-singer-feather.jpg)

See the [filter index](README.md) for the full catalogue.
