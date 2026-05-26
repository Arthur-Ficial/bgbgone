# `zoom-blur`

> radial zoom blur (CIZoomBlur)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `zoom-blur=center=X,Y:amount=A` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:zoom-blur=center=0.5,0.5:amount=20"
```

![`all:zoom-blur=center=0.5,0.5:amount=20` on red-panda](../images/filters/zoom-blur.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:zoom-blur=center=0.5,0.5:amount=20"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:zoom-blur=center=0.5,0.5:amount=20"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:zoom-blur=center=0.5,0.5:amount=20"
```

![`zoom-blur` panels on yoga](../images/filters/panels/yoga-zoom-blur.jpg)
![`zoom-blur` panels on woman-singer](../images/filters/panels/woman-singer-zoom-blur.jpg)

See the [filter index](README.md) for the full catalogue.
