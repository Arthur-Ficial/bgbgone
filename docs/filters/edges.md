# `edges`

> edge detection (CIEdges)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `edges=intensity` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:edges=2.5"
```

![`all:edges=2.5` on red-panda](../images/filters/edges.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:edges=2.5"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:edges=2.5"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:edges=2.5"
```

![`edges` panels on yoga](../images/filters/panels/yoga-edges.jpg)
![`edges` panels on woman-singer](../images/filters/panels/woman-singer-edges.jpg)

See the [filter index](README.md) for the full catalogue.
