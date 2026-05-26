# `flip`

> mirror subject (CIAffineTransform)

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `flip=horizontal|vertical` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:flip=horizontal"
```

![`fg:flip=horizontal` on red-panda](../images/filters/flip.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:flip=horizontal"
```

![`flip` panels on yoga](../images/filters/panels/yoga-flip.jpg)
![`flip` panels on woman-singer](../images/filters/panels/woman-singer-flip.jpg)

See the [filter index](README.md) for the full catalogue.
