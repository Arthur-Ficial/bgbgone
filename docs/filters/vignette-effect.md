# `vignette-effect`

> positioned vignette, composite only (CIVignetteEffect)

| Field | Value |
|---|---|
| **Layers** | composite |
| **Signature** | `vignette-effect=center=X,Y:radius=R:intensity=I` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "composite:vignette-effect=center=0.5,0.5:radius=1.5:intensity=1"
```

![`composite:vignette-effect=center=0.5,0.5:radius=1.5:intensity=1` on red-panda](../images/filters/vignette-effect.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg color:#1a2233 --filter "composite:vignette-effect=center=0.5,0.5:radius=1.5:intensity=1"
```

![`vignette-effect` panels on yoga](../images/filters/panels/yoga-vignette-effect.jpg)
![`vignette-effect` panels on woman-singer](../images/filters/panels/woman-singer-vignette-effect.jpg)

See the [filter index](README.md) for the full catalogue.
