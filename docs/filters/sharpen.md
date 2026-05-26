# `sharpen`

> luminance sharpen (CISharpenLuminance)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `sharpen=amount` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:sharpen=0.5"
```

![`all:sharpen=0.5` on red-panda](../images/filters/sharpen.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:sharpen=0.5"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:sharpen=0.5"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:sharpen=0.5"
```

![`sharpen` panels on yoga](../images/filters/panels/yoga-sharpen.jpg)
![`sharpen` panels on woman-singer](../images/filters/panels/woman-singer-sharpen.jpg)

See the [filter index](README.md) for the full catalogue.
