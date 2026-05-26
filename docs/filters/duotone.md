# `duotone`

> two-colour map by luminance (CIColorMatrix)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `duotone=dark=#hex:light=#hex` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:duotone=dark=#003366:light=#ffcc00"
```

![`all:duotone=dark=#003366:light=#ffcc00` on red-panda](../images/filters/duotone.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:duotone=dark=#003366:light=#ffcc00"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:duotone=dark=#003366:light=#ffcc00"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:duotone=dark=#003366:light=#ffcc00"
```

![`duotone` panels on yoga](../images/filters/panels/yoga-duotone.jpg)
![`duotone` panels on woman-singer](../images/filters/panels/woman-singer-duotone.jpg)

See the [filter index](README.md) for the full catalogue.
