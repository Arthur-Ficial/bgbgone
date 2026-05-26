# `pixelate`

> block pixelation (CIPixellate)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `pixelate=size` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:pixelate=20" -o red-panda-pixelate.jpg
```

After `all:pixelate=20`:

![red-panda after all:pixelate=20](../images/filters/pixelate.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:pixelate"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:pixelate"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:pixelate"
```

Panels (`original | bg | fg | all`):

![`pixelate` panels on yoga](../images/filters/panels/yoga-pixelate.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:pixelate"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:pixelate"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:pixelate"
```

Panels (`original | bg | fg | all`):

![`pixelate` panels on woman-singer](../images/filters/panels/woman-singer-pixelate.jpg)

See the [filter index](README.md) for the full catalogue.
