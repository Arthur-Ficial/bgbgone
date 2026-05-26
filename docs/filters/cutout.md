# `cutout`

> subject becomes a hole; background stays

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `cutout` |
| **Note** | introduces alpha — use PNG output or pass `--bg` |

## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:cutout"
```

![`fg:cutout` on red-panda](../images/filters/cutout.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:cutout"
```

![`cutout` panels on yoga](../images/filters/panels/yoga-cutout.jpg)
![`cutout` panels on woman-singer](../images/filters/panels/woman-singer-cutout.jpg)

See the [filter index](README.md) for the full catalogue.
