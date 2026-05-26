# `vignette`

> darken edges, composite only (CIVignette)

| Field | Value |
|---|---|
| **Layers** | composite |
| **Signature** | `vignette=intensity:radius` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "composite:vignette=intensity=0.5:radius=10" -o red-panda-vignette.jpg
```

After `composite:vignette=intensity=0.5:radius=10`:

![red-panda after composite:vignette=intensity=0.5:radius=10](../images/filters/vignette.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "composite:vignette"
```

Panels (`original | bg | fg | all`):

![`vignette` panels on yoga](../images/filters/panels/yoga-vignette.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "composite:vignette"
```

Panels (`original | bg | fg | all`):

![`vignette` panels on woman-singer](../images/filters/panels/woman-singer-vignette.jpg)

See the [filter index](README.md) for the full catalogue.
