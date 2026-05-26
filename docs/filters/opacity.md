# `opacity`

> scale alpha by value 0..1 (CIColorMatrix)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `opacity=value` |
| **Note** | introduces alpha — use PNG output or pass `--bg` |

## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:opacity=0.7" -o red-panda-opacity.jpg
```

After `all:opacity=0.7`:

![red-panda after all:opacity=0.7](../images/filters/opacity.jpg)



See the [filter index](README.md) for the full catalogue.
