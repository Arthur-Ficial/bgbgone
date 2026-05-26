# `emboss`

> raised relief via 3x3 convolution

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `emboss` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:emboss" -o red-panda-emboss.jpg
```

After `all:emboss`:

![red-panda after all:emboss](../images/filters/emboss.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:emboss"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:emboss"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:emboss"
```

Panels (`original | bg | fg | all`):

![`emboss` panels on yoga](../images/filters/panels/yoga-emboss.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:emboss"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:emboss"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:emboss"
```

Panels (`original | bg | fg | all`):

![`emboss` panels on woman-singer](../images/filters/panels/woman-singer-emboss.jpg)

See the [filter index](README.md) for the full catalogue.
