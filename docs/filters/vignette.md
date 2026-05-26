# `vignette`

> darken edges, composite only (CIVignette)

| Field | Value |
|---|---|
| **Layers** | composite |
| **Signature** | `vignette=intensity:radius` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "composite:vignette=intensity=0.5:radius=10"
```

![`composite:vignette=intensity=0.5:radius=10` on red-panda](../images/filters/vignette.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg color:#1a2233 --filter "composite:vignette=intensity=0.5:radius=10"
```

![`vignette` panels on yoga](../images/filters/panels/yoga-vignette.jpg)
![`vignette` panels on woman-singer](../images/filters/panels/woman-singer-vignette.jpg)

See the [filter index](README.md) for the full catalogue.
