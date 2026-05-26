# `desaturate`

> scale saturation by 1-amount (CIColorControls)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `desaturate=amount` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:desaturate=0.5"
```

![`all:desaturate=0.5` on red-panda](../images/filters/desaturate.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:desaturate=0.5"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:desaturate=0.5"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:desaturate=0.5"
```

![`desaturate` panels on yoga](../images/filters/panels/yoga-desaturate.jpg)
![`desaturate` panels on woman-singer](../images/filters/panels/woman-singer-desaturate.jpg)

See the [filter index](README.md) for the full catalogue.
