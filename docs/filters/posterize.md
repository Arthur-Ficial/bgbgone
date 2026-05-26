# `posterize`

> quantise to N colour levels (CIColorPosterize)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `posterize=levels` |


## Example — red-panda, `fg:posterize=4` (subject filter, background preserved)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:posterize=4" -o red-panda-posterize.jpg
```

![red-panda after `fg:posterize=4`](../images/filters/posterize.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:posterize"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:posterize"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:posterize"
```

Panels (`original | bg | fg | all`):

![`posterize` panels on yoga](../images/filters/panels/yoga-posterize.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:posterize"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:posterize"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:posterize"
```

Panels (`original | bg | fg | all`):

![`posterize` panels on woman-singer](../images/filters/panels/woman-singer-posterize.jpg)

See the [filter index](README.md) for the full catalogue.
