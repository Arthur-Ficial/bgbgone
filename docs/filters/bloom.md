# `bloom`

> soft glow on highlights, composite only (CIBloom)

| Field | Value |
|---|---|
| **Layers** | composite |
| **Signature** | `bloom=intensity:radius` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "composite:bloom=intensity=0.5:radius=10" -o red-panda-bloom.jpg
```

After `composite:bloom=intensity=0.5:radius=10`:

![red-panda after composite:bloom=intensity=0.5:radius=10](../images/filters/bloom.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "composite:bloom"
```

Panels (`original | bg | fg | all`):

![`bloom` panels on yoga](../images/filters/panels/yoga-bloom.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "composite:bloom"
```

Panels (`original | bg | fg | all`):

![`bloom` panels on woman-singer](../images/filters/panels/woman-singer-bloom.jpg)

See the [filter index](README.md) for the full catalogue.
