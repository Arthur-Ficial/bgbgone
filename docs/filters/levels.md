# `levels`

> Photoshop-style levels (CIColorMatrix + CIGammaAdjust)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `levels=black=B:white=W:gamma=G` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:levels=black=20:white=235:gamma=1.0" -o red-panda-levels.jpg
```

After `all:levels=black=20:white=235:gamma=1.0`:

![red-panda after all:levels=black=20:white=235:gamma=1.0](../images/filters/levels.jpg)


## Per-layer panels — yoga (`--type person`)

Original input:

![yoga input](../../Tests/fixtures/yoga.jpg)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:levels"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:levels"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:levels"
```

Panels (`original | bg | fg | all`):

![`levels` panels on yoga](../images/filters/panels/yoga-levels.jpg)
## Per-layer panels — woman-singer (`--type person`)

Original input:

![woman-singer input](../../Tests/fixtures/woman-singer.jpg)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:levels"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:levels"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:levels"
```

Panels (`original | bg | fg | all`):

![`levels` panels on woman-singer](../images/filters/panels/woman-singer-levels.jpg)

See the [filter index](README.md) for the full catalogue.
