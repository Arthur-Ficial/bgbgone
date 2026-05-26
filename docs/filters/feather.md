# `feather`

> soften matte edge (CIGaussianBlur on mask)

| Field | Value |
|---|---|
| **Layers** | mask |
| **Signature** | `feather=radius` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "mask:feather=8" -o red-panda-feather.jpg
```

After `mask:feather=8`:

![red-panda after mask:feather=8](../images/filters/feather.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "mask:feather"
```

Panels (`original | bg | fg | all`):

![`feather` panels on yoga](../images/filters/panels/yoga-feather.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "mask:feather"
```

Panels (`original | bg | fg | all`):

![`feather` panels on woman-singer](../images/filters/panels/woman-singer-feather.jpg)

See the [filter index](README.md) for the full catalogue.
