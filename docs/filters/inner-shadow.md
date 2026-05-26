# `inner-shadow`

> shadow inside the matte (invert+blur+intersect+tint)

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `inner-shadow=blur=B:offset=X,Y:opacity=O:color=#hex` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:inner-shadow=blur=12:offset=4,4:opacity=0.5:color=#000" -o red-panda-inner-shadow.jpg
```

After `fg:inner-shadow=blur=12:offset=4,4:opacity=0.5:color=#000`:

![red-panda after fg:inner-shadow=blur=12:offset=4,4:opacity=0.5:color=#000](../images/filters/inner-shadow.jpg)


## Per-layer panels — yoga (`--type person`)

Original input:

![yoga input](../../Tests/fixtures/yoga.jpg)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:inner-shadow"
```

Panels (`original | bg | fg | all`):

![`inner-shadow` panels on yoga](../images/filters/panels/yoga-inner-shadow.jpg)
## Per-layer panels — woman-singer (`--type person`)

Original input:

![woman-singer input](../../Tests/fixtures/woman-singer.jpg)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:inner-shadow"
```

Panels (`original | bg | fg | all`):

![`inner-shadow` panels on woman-singer](../images/filters/panels/woman-singer-inner-shadow.jpg)

See the [filter index](README.md) for the full catalogue.
