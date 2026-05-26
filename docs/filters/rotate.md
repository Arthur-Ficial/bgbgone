# `rotate`

> rotate subject around centre (CIAffineTransform)

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `rotate=degrees` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:rotate=15"
```

![`fg:rotate=15` on red-panda](../images/filters/rotate.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:rotate=15"
```

![`rotate` panels on yoga](../images/filters/panels/yoga-rotate.jpg)
![`rotate` panels on woman-singer](../images/filters/panels/woman-singer-rotate.jpg)

See the [filter index](README.md) for the full catalogue.
