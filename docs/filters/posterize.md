# `posterize`

> quantise to N colour levels (CIColorPosterize)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `posterize=levels` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:posterize=4"
```

![`all:posterize=4` on red-panda](../images/filters/posterize.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:posterize=4"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:posterize=4"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:posterize=4"
```

![`posterize` panels on yoga](../images/filters/panels/yoga-posterize.jpg)
![`posterize` panels on woman-singer](../images/filters/panels/woman-singer-posterize.jpg)

See the [filter index](README.md) for the full catalogue.
