# `threshold`

> binarise matte (CIColorThreshold)

| Field | Value |
|---|---|
| **Layers** | mask |
| **Signature** | `threshold=value` |


## Example — red-panda, `mask:threshold=0.5` (subject filter, background preserved)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "mask:threshold=0.5" -o red-panda-threshold.jpg
```

![red-panda after `mask:threshold=0.5`](../images/filters/threshold.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "mask:threshold"
```

Panels (`original | bg | fg | all`):

![`threshold` panels on yoga](../images/filters/panels/yoga-threshold.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "mask:threshold"
```

Panels (`original | bg | fg | all`):

![`threshold` panels on woman-singer](../images/filters/panels/woman-singer-threshold.jpg)

See the [filter index](README.md) for the full catalogue.
