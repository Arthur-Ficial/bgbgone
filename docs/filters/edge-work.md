# `edge-work`

> line-art edges (CIEdgeWork)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `edge-work=radius` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:edge-work=3" -o red-panda-edge-work.jpg
```

After `all:edge-work=3`:

![red-panda after all:edge-work=3](../images/filters/edge-work.jpg)


## Per-layer panels — yoga (`--type person`)

Original input:

![yoga input](../../Tests/fixtures/yoga.jpg)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:edge-work"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:edge-work"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:edge-work"
```

Panels (`original | bg | fg | all`):

![`edge-work` panels on yoga](../images/filters/panels/yoga-edge-work.jpg)
## Per-layer panels — woman-singer (`--type person`)

Original input:

![woman-singer input](../../Tests/fixtures/woman-singer.jpg)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:edge-work"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:edge-work"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:edge-work"
```

Panels (`original | bg | fg | all`):

![`edge-work` panels on woman-singer](../images/filters/panels/woman-singer-edge-work.jpg)

See the [filter index](README.md) for the full catalogue.
