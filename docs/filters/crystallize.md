# `crystallize`

> Voronoi mosaic (CICrystallize)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `crystallize=radius` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:crystallize=20"
```

![`all:crystallize=20` on red-panda](../images/filters/crystallize.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:crystallize=20"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:crystallize=20"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:crystallize=20"
```

![`crystallize` panels on yoga](../images/filters/panels/yoga-crystallize.jpg)
![`crystallize` panels on woman-singer](../images/filters/panels/woman-singer-crystallize.jpg)

See the [filter index](README.md) for the full catalogue.
