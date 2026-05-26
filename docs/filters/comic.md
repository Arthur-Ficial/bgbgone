# `comic`

> halftone comic-book effect (CIComicEffect)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `comic` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:comic"
```

![`all:comic` on red-panda](../images/filters/comic.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:comic"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:comic"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:comic"
```

![`comic` panels on yoga](../images/filters/panels/yoga-comic.jpg)
![`comic` panels on woman-singer](../images/filters/panels/woman-singer-comic.jpg)

See the [filter index](README.md) for the full catalogue.
