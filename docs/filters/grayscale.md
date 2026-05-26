# `grayscale`

> remove all colour saturation (CIColorControls)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `grayscale` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:grayscale" -o red-panda-grayscale.jpg
```

After `all:grayscale`:

![red-panda after all:grayscale](../images/filters/grayscale.jpg)


## Per-layer panels — yoga (`--type person`)

Original input:

![yoga input](../../Tests/fixtures/yoga.jpg)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:grayscale"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:grayscale"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:grayscale"
```

Panels (`original | bg | fg | all`):

![`grayscale` panels on yoga](../images/filters/panels/yoga-grayscale.jpg)
## Per-layer panels — woman-singer (`--type person`)

Original input:

![woman-singer input](../../Tests/fixtures/woman-singer.jpg)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:grayscale"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:grayscale"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:grayscale"
```

Panels (`original | bg | fg | all`):

![`grayscale` panels on woman-singer](../images/filters/panels/woman-singer-grayscale.jpg)

See the [filter index](README.md) for the full catalogue.
