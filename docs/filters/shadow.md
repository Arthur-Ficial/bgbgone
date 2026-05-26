# `shadow`

> per-subject drop shadow (translate+blur+tint+composite)

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `shadow=blur=B:offset=X,Y:opacity=O:color=#hex` |
| **Note** | introduces alpha — use PNG output or pass `--bg` |

## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:shadow=blur=12:offset=4,4:opacity=0.5:color=#000"
```

![`fg:shadow=blur=12:offset=4,4:opacity=0.5:color=#000` on red-panda](../images/filters/shadow.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:shadow=blur=12:offset=4,4:opacity=0.5:color=#000"
```

![`shadow` panels on yoga](../images/filters/panels/yoga-shadow.jpg)
![`shadow` panels on woman-singer](../images/filters/panels/woman-singer-shadow.jpg)

See the [filter index](README.md) for the full catalogue.
