# `negate`

> invert RGB (CIColorInvert)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `negate` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:negate" -o red-panda-negate.jpg
```

After `all:negate`:

![red-panda after all:negate](../images/filters/negate.jpg)


## Per-layer panels — yoga (`--type person`)

Original input:

![yoga input](../../Tests/fixtures/yoga.jpg)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:negate"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:negate"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:negate"
```

Panels (`original | bg | fg | all`):

![`negate` panels on yoga](../images/filters/panels/yoga-negate.jpg)
## Per-layer panels — woman-singer (`--type person`)

Original input:

![woman-singer input](../../Tests/fixtures/woman-singer.jpg)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:negate"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:negate"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:negate"
```

Panels (`original | bg | fg | all`):

![`negate` panels on woman-singer](../images/filters/panels/woman-singer-negate.jpg)

See the [filter index](README.md) for the full catalogue.
