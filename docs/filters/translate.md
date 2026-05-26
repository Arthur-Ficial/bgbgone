# `translate`

> shift subject in pixels (CIAffineTransform)

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `translate=dx,dy` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:translate=-200,200"
```

![`fg:translate=-200,200` on red-panda](../images/filters/translate.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:translate=-200,200"
```

![`translate` panels on yoga](../images/filters/panels/yoga-translate.jpg)
![`translate` panels on woman-singer](../images/filters/panels/woman-singer-translate.jpg)

See the [filter index](README.md) for the full catalogue.
