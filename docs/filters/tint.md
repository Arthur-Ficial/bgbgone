# `tint`

> blend toward a tint colour (CIColorMonochrome)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `tint=color=#hex:amount=A` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:tint=color=#0066ff:amount=0.5" -o red-panda-tint.jpg
```

After `all:tint=color=#0066ff:amount=0.5`:

![red-panda after all:tint=color=#0066ff:amount=0.5](../images/filters/tint.jpg)


## Per-layer panels — yoga (`--type person`)

Original input:

![yoga input](../../Tests/fixtures/yoga.jpg)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:tint"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:tint"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:tint"
```

Panels (`original | bg | fg | all`):

![`tint` panels on yoga](../images/filters/panels/yoga-tint.jpg)
## Per-layer panels — woman-singer (`--type person`)

Original input:

![woman-singer input](../../Tests/fixtures/woman-singer.jpg)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:tint"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:tint"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:tint"
```

Panels (`original | bg | fg | all`):

![`tint` panels on woman-singer](../images/filters/panels/woman-singer-tint.jpg)

See the [filter index](README.md) for the full catalogue.
