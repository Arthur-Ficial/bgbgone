# `crystallize`

> Voronoi mosaic (CICrystallize)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `crystallize=radius` |


## Example — red-panda, `fg:crystallize=20` (subject filter, background preserved)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:crystallize=20" -o red-panda-crystallize.jpg
```

![red-panda after `fg:crystallize=20`](../images/filters/crystallize.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:crystallize"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:crystallize"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:crystallize"
```

Panels (`original | bg | fg | all`):

![`crystallize` panels on yoga](../images/filters/panels/yoga-crystallize.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:crystallize"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:crystallize"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:crystallize"
```

Panels (`original | bg | fg | all`):

![`crystallize` panels on woman-singer](../images/filters/panels/woman-singer-crystallize.jpg)

See the [filter index](README.md) for the full catalogue.
