# `duotone`

> two-colour map by luminance (CIColorMatrix)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `duotone=dark=#hex:light=#hex` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:duotone=dark=#003366:light=#ffcc00" -o red-panda-duotone.jpg
```

After `all:duotone=dark=#003366:light=#ffcc00`:

![red-panda after all:duotone=dark=#003366:light=#ffcc00](../images/filters/duotone.jpg)


## Per-layer panels — yoga (`--type person`)

Original input:

![yoga input](../../Tests/fixtures/yoga.jpg)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:duotone"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:duotone"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:duotone"
```

Panels (`original | bg | fg | all`):

![`duotone` panels on yoga](../images/filters/panels/yoga-duotone.jpg)
## Per-layer panels — woman-singer (`--type person`)

Original input:

![woman-singer input](../../Tests/fixtures/woman-singer.jpg)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:duotone"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:duotone"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:duotone"
```

Panels (`original | bg | fg | all`):

![`duotone` panels on woman-singer](../images/filters/panels/woman-singer-duotone.jpg)

See the [filter index](README.md) for the full catalogue.
