# `scale`

> scale subject around centre (CIAffineTransform)

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `scale=factor` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:scale=0.75" -o red-panda-scale.jpg
```

After `fg:scale=0.75`:

![red-panda after fg:scale=0.75](../images/filters/scale.jpg)


## Per-layer panels — yoga (`--type person`)

Original input:

![yoga input](../../Tests/fixtures/yoga.jpg)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:scale"
```

Panels (`original | bg | fg | all`):

![`scale` panels on yoga](../images/filters/panels/yoga-scale.jpg)
## Per-layer panels — woman-singer (`--type person`)

Original input:

![woman-singer input](../../Tests/fixtures/woman-singer.jpg)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:scale"
```

Panels (`original | bg | fg | all`):

![`scale` panels on woman-singer](../images/filters/panels/woman-singer-scale.jpg)

See the [filter index](README.md) for the full catalogue.
