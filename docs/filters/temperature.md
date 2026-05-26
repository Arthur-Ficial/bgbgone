# `temperature`

> shift colour temperature in Kelvin (CITemperatureAndTint)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `temperature=K` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:temperature=6500"
```

![`all:temperature=6500` on red-panda](../images/filters/temperature.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:temperature=6500"
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "bg:temperature=6500"
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:temperature=6500"
```

![`temperature` panels on yoga](../images/filters/panels/yoga-temperature.jpg)
![`temperature` panels on woman-singer](../images/filters/panels/woman-singer-temperature.jpg)

See the [filter index](README.md) for the full catalogue.
