# `threshold`

> binarise matte (CIColorThreshold)

| Field | Value |
|---|---|
| **Layers** | mask |
| **Signature** | `threshold=value` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "mask:threshold=0.5"
```

![`mask:threshold=0.5` on red-panda](../images/filters/threshold.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg color:#1a2233 --filter "mask:threshold=0.5"
```

![`threshold` panels on yoga](../images/filters/panels/yoga-threshold.jpg)
![`threshold` panels on woman-singer](../images/filters/panels/woman-singer-threshold.jpg)

See the [filter index](README.md) for the full catalogue.
