# `motion-blur`

> directional blur (CIMotionBlur)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `motion-blur=radius:angle` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:motion-blur=radius=10:angle=45"
```

![`all:motion-blur=radius=10:angle=45` on red-panda](../images/filters/motion-blur.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:motion-blur=radius=10:angle=45"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:motion-blur=radius=10:angle=45"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:motion-blur=radius=10:angle=45"
```

![`motion-blur` panels on yoga](../images/filters/panels/yoga-motion-blur.jpg)
![`motion-blur` panels on woman-singer](../images/filters/panels/woman-singer-motion-blur.jpg)

See the [filter index](README.md) for the full catalogue.
