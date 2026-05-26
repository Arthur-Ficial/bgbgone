# `glow`

> subject glow halo (blur+tint+composite)

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `glow=color=#hex:radius=R:intensity=I` |
| **Note** | introduces alpha — use PNG output or pass `--bg` |

## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:glow=color=#ffe080:radius=10:intensity=0.6"
```

![`fg:glow=color=#ffe080:radius=10:intensity=0.6` on red-panda](../images/filters/glow.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:glow=color=#ffe080:radius=10:intensity=0.6"
```

![`glow` panels on yoga](../images/filters/panels/yoga-glow.jpg)
![`glow` panels on woman-singer](../images/filters/panels/woman-singer-glow.jpg)

See the [filter index](README.md) for the full catalogue.
