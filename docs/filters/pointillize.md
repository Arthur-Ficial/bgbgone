# `pointillize`

> Seurat dot effect (CIPointillize)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `pointillize=radius` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:pointillize=5"
```

![`all:pointillize=5` on red-panda](../images/filters/pointillize.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:pointillize=5"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:pointillize=5"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:pointillize=5"
```

![`pointillize` panels on yoga](../images/filters/panels/yoga-pointillize.jpg)
![`pointillize` panels on woman-singer](../images/filters/panels/woman-singer-pointillize.jpg)

See the [filter index](README.md) for the full catalogue.
