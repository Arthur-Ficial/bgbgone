# `matte`

> emit the alpha mask itself as final RGBA

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `matte` |
| **Note** | introduces alpha — use PNG output or pass `--bg` |

## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:matte"
```

![`fg:matte` on red-panda](../images/filters/matte.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:matte"
```

![`matte` panels on yoga](../images/filters/panels/yoga-matte.jpg)
![`matte` panels on woman-singer](../images/filters/panels/woman-singer-matte.jpg)

See the [filter index](README.md) for the full catalogue.
