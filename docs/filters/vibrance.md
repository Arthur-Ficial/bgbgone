# `vibrance`

> boost low-saturation colours (CIVibrance)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `vibrance=amount` |


## Example — red-panda, `fg:vibrance=0.5` (subject filter, background preserved)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:vibrance=0.5" -o red-panda-vibrance.jpg
```

![red-panda after `fg:vibrance=0.5`](../images/filters/vibrance.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:vibrance"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:vibrance"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:vibrance"
```

Panels (`original | bg | fg | all`):

![`vibrance` panels on yoga](../images/filters/panels/yoga-vibrance.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:vibrance"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:vibrance"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:vibrance"
```

Panels (`original | bg | fg | all`):

![`vibrance` panels on woman-singer](../images/filters/panels/woman-singer-vibrance.jpg)

See the [filter index](README.md) for the full catalogue.
