# `gamma`

> gamma curve, typical 0.5..2.5 (CIGammaAdjust)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `gamma=value` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:gamma=1.2" -o red-panda-gamma.jpg
```

After `all:gamma=1.2`:

![red-panda after all:gamma=1.2](../images/filters/gamma.jpg)


## Per-layer panels — yoga (`--type person`)

Original input:

![yoga input](../../Tests/fixtures/yoga.jpg)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:gamma"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:gamma"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:gamma"
```

Panels (`original | bg | fg | all`):

![`gamma` panels on yoga](../images/filters/panels/yoga-gamma.jpg)
## Per-layer panels — woman-singer (`--type person`)

Original input:

![woman-singer input](../../Tests/fixtures/woman-singer.jpg)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:gamma"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:gamma"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:gamma"
```

Panels (`original | bg | fg | all`):

![`gamma` panels on woman-singer](../images/filters/panels/woman-singer-gamma.jpg)

See the [filter index](README.md) for the full catalogue.
