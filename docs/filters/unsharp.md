# `unsharp`

> unsharp mask (CIUnsharpMask)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `unsharp=radius:intensity` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:unsharp=radius=2.5:intensity=0.5"
```

![`all:unsharp=radius=2.5:intensity=0.5` on red-panda](../images/filters/unsharp.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:unsharp=radius=2.5:intensity=0.5"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:unsharp=radius=2.5:intensity=0.5"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:unsharp=radius=2.5:intensity=0.5"
```

![`unsharp` panels on yoga](../images/filters/panels/yoga-unsharp.jpg)
![`unsharp` panels on woman-singer](../images/filters/panels/woman-singer-unsharp.jpg)

See the [filter index](README.md) for the full catalogue.
