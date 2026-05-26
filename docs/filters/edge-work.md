# `edge-work`

> line-art edges (CIEdgeWork)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `edge-work=radius` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:edge-work=3"
```

![`all:edge-work=3` on red-panda](../images/filters/edge-work.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:edge-work=3"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:edge-work=3"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:edge-work=3"
```

![`edge-work` panels on yoga](../images/filters/panels/yoga-edge-work.jpg)
![`edge-work` panels on woman-singer](../images/filters/panels/woman-singer-edge-work.jpg)

See the [filter index](README.md) for the full catalogue.
