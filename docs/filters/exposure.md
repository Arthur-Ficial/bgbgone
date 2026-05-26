# `exposure`

> +/- stops, typical -2..+2 (CIExposureAdjust)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `exposure=stops` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:exposure=1.0"
```

![`all:exposure=1.0` on red-panda](../images/filters/exposure.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:exposure=1.0"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:exposure=1.0"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:exposure=1.0"
```

![`exposure` panels on yoga](../images/filters/panels/yoga-exposure.jpg)
![`exposure` panels on woman-singer](../images/filters/panels/woman-singer-exposure.jpg)

See the [filter index](README.md) for the full catalogue.
