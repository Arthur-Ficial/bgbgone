# `expand`

> grow matte dilation (CIMorphologyMaximum)

| Field | Value |
|---|---|
| **Layers** | mask |
| **Signature** | `expand=pixels` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "mask:expand=3"
```

![`mask:expand=3` on red-panda](../images/filters/expand.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg color:#1a2233 --filter "mask:expand=3"
```

![`expand` panels on yoga](../images/filters/panels/yoga-expand.jpg)
![`expand` panels on woman-singer](../images/filters/panels/woman-singer-expand.jpg)

See the [filter index](README.md) for the full catalogue.
