# `threshold`

> binarise matte (CIColorThreshold)

| Field | Value |
|---|---|
| **Layers** | mask |
| **Signature** | `threshold=value` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "mask:threshold=0.5" -o red-panda-threshold.jpg
```

After `mask:threshold=0.5`:

![red-panda after mask:threshold=0.5](../images/filters/threshold.jpg)


## Per-layer panels — yoga (`--type person`)

Original input:

![yoga input](../../Tests/fixtures/yoga.jpg)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "mask:threshold"
```

Panels (`original | bg | fg | all`):

![`threshold` panels on yoga](../images/filters/panels/yoga-threshold.jpg)
## Per-layer panels — woman-singer (`--type person`)

Original input:

![woman-singer input](../../Tests/fixtures/woman-singer.jpg)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "mask:threshold"
```

Panels (`original | bg | fg | all`):

![`threshold` panels on woman-singer](../images/filters/panels/woman-singer-threshold.jpg)

See the [filter index](README.md) for the full catalogue.
