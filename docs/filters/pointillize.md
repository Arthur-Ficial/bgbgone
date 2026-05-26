# `pointillize`

> Seurat dot effect (CIPointillize)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `pointillize=radius` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:pointillize=5" -o red-panda-pointillize.jpg
```

After `all:pointillize=5`:

![red-panda after all:pointillize=5](../images/filters/pointillize.jpg)


## Per-layer panels — yoga (`--type person`)

Original input:

![yoga input](../../Tests/fixtures/yoga.jpg)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:pointillize"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:pointillize"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:pointillize"
```

Panels (`original | bg | fg | all`):

![`pointillize` panels on yoga](../images/filters/panels/yoga-pointillize.jpg)
## Per-layer panels — woman-singer (`--type person`)

Original input:

![woman-singer input](../../Tests/fixtures/woman-singer.jpg)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:pointillize"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:pointillize"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:pointillize"
```

Panels (`original | bg | fg | all`):

![`pointillize` panels on woman-singer](../images/filters/panels/woman-singer-pointillize.jpg)

See the [filter index](README.md) for the full catalogue.
