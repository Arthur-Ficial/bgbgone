# `noise`

> additive film grain (CIRandomGenerator + composite)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `noise=amount` |


## Example — red-panda, `fg:noise=0.1` (subject filter, background preserved)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:noise=0.1" -o red-panda-noise.jpg
```

![red-panda after `fg:noise=0.1`](../images/filters/noise.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:noise"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:noise"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:noise"
```

Panels (`original | bg | fg | all`):

![`noise` panels on yoga](../images/filters/panels/yoga-noise.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:noise"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:noise"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:noise"
```

Panels (`original | bg | fg | all`):

![`noise` panels on woman-singer](../images/filters/panels/woman-singer-noise.jpg)

See the [filter index](README.md) for the full catalogue.
