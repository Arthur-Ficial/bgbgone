# `translate`

> shift subject in pixels (CIAffineTransform)

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `translate=dx,dy` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:translate=-200,200" -o red-panda-translate.jpg
```

After `fg:translate=-200,200`:

![red-panda after fg:translate=-200,200](../images/filters/translate.jpg)


## Per-layer panels — yoga (`--type person`)

Original input:

![yoga input](../../Tests/fixtures/yoga.jpg)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:translate"
```

Panels (`original | bg | fg | all`):

![`translate` panels on yoga](../images/filters/panels/yoga-translate.jpg)
## Per-layer panels — woman-singer (`--type person`)

Original input:

![woman-singer input](../../Tests/fixtures/woman-singer.jpg)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:translate"
```

Panels (`original | bg | fg | all`):

![`translate` panels on woman-singer](../images/filters/panels/woman-singer-translate.jpg)

See the [filter index](README.md) for the full catalogue.
