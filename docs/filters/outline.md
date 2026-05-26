# `outline`

> coloured outline outside the matte (morphology+subtract+tint)

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `outline=color=#hex:width=N` |
| **Note** | introduces alpha — use PNG output or pass `--bg` |

## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:outline=color=#ffffff:width=3"
```

![`fg:outline=color=#ffffff:width=3` on red-panda](../images/filters/outline.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:outline=color=#ffffff:width=3"
```

![`outline` panels on yoga](../images/filters/panels/yoga-outline.jpg)
![`outline` panels on woman-singer](../images/filters/panels/woman-singer-outline.jpg)

See the [filter index](README.md) for the full catalogue.
