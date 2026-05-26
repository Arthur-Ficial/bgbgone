# `gloom`

> dark-glow inverse of bloom, composite only (CIGloom)

| Field | Value |
|---|---|
| **Layers** | composite |
| **Signature** | `gloom=intensity:radius` |


## Example — red-panda, `composite:gloom=intensity=0.5:radius=10` (subject filter, background preserved)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "composite:gloom=intensity=0.5:radius=10" -o red-panda-gloom.jpg
```

![red-panda after `composite:gloom=intensity=0.5:radius=10`](../images/filters/gloom.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "composite:gloom"
```

Panels (`original | bg | fg | all`):

![`gloom` panels on yoga](../images/filters/panels/yoga-gloom.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "composite:gloom"
```

Panels (`original | bg | fg | all`):

![`gloom` panels on woman-singer](../images/filters/panels/woman-singer-gloom.jpg)

See the [filter index](README.md) for the full catalogue.
