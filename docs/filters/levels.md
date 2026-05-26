# `levels`

> Photoshop-style levels (CIColorMatrix + CIGammaAdjust)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `levels=black=B:white=W:gamma=G` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:levels=black=20:white=235:gamma=1.0"
```

![`all:levels=black=20:white=235:gamma=1.0` on red-panda](../images/filters/levels.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:levels=black=20:white=235:gamma=1.0"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:levels=black=20:white=235:gamma=1.0"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:levels=black=20:white=235:gamma=1.0"
```

![`levels` panels on yoga](../images/filters/panels/yoga-levels.jpg)
![`levels` panels on woman-singer](../images/filters/panels/woman-singer-levels.jpg)

See the [filter index](README.md) for the full catalogue.
