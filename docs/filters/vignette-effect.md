# `vignette-effect`

> positioned vignette, composite only (CIVignetteEffect)

| Field | Value |
|---|---|
| **Layers** | composite |
| **Signature** | `vignette-effect=center=X,Y:radius=R:intensity=I` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "composite:vignette-effect=center=0.5,0.5:radius=1.5:intensity=1" -o red-panda-vignette-effect.jpg
```

After `composite:vignette-effect=center=0.5,0.5:radius=1.5:intensity=1`:

![red-panda after composite:vignette-effect=center=0.5,0.5:radius=1.5:intensity=1](../images/filters/vignette-effect.jpg)


## Per-layer panels — yoga (`--type person`)

Original input:

![yoga input](../../Tests/fixtures/yoga.jpg)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "composite:vignette-effect"
```

Panels (`original | bg | fg | all`):

![`vignette-effect` panels on yoga](../images/filters/panels/yoga-vignette-effect.jpg)
## Per-layer panels — woman-singer (`--type person`)

Original input:

![woman-singer input](../../Tests/fixtures/woman-singer.jpg)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "composite:vignette-effect"
```

Panels (`original | bg | fg | all`):

![`vignette-effect` panels on woman-singer](../images/filters/panels/woman-singer-vignette-effect.jpg)

See the [filter index](README.md) for the full catalogue.
