# `expand`

> grow matte dilation (CIMorphologyMaximum)

| Field | Value |
|---|---|
| **Layers** | mask |
| **Signature** | `expand=pixels` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "mask:expand=3" -o red-panda-expand.jpg
```

After `mask:expand=3`:

![red-panda after mask:expand=3](../images/filters/expand.jpg)


## Per-layer panels — yoga (`--type person`)

Original input:

![yoga input](../../Tests/fixtures/yoga.jpg)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "mask:expand"
```

Panels (`original | bg | fg | all`):

![`expand` panels on yoga](../images/filters/panels/yoga-expand.jpg)
## Per-layer panels — woman-singer (`--type person`)

Original input:

![woman-singer input](../../Tests/fixtures/woman-singer.jpg)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "mask:expand"
```

Panels (`original | bg | fg | all`):

![`expand` panels on woman-singer](../images/filters/panels/woman-singer-expand.jpg)

See the [filter index](README.md) for the full catalogue.
