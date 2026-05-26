# `edges`

> edge detection (CIEdges)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `edges=intensity` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:edges=2.5" -o red-panda-edges.jpg
```

After `all:edges=2.5`:

![red-panda after all:edges=2.5](../images/filters/edges.jpg)


## Per-layer panels — yoga (`--type person`)

Original input:

![yoga input](../../Tests/fixtures/yoga.jpg)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:edges"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:edges"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:edges"
```

Panels (`original | bg | fg | all`):

![`edges` panels on yoga](../images/filters/panels/yoga-edges.jpg)
## Per-layer panels — woman-singer (`--type person`)

Original input:

![woman-singer input](../../Tests/fixtures/woman-singer.jpg)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:edges"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:edges"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:edges"
```

Panels (`original | bg | fg | all`):

![`edges` panels on woman-singer](../images/filters/panels/woman-singer-edges.jpg)

See the [filter index](README.md) for the full catalogue.
