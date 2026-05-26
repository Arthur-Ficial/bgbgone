# `opacity`

> scale alpha by value 0..1 (CIColorMatrix)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `opacity=value` |
| **Note** | introduces alpha — output here is JPEG over the source bg; use `-o out.png` for true transparent output |

## Example — red-panda, `fg:opacity=0.7` (subject filter, background preserved)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:opacity=0.7" -o red-panda-opacity.jpg
```

![red-panda after `fg:opacity=0.7`](../images/filters/opacity.jpg)



See the [filter index](README.md) for the full catalogue.
