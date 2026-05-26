# `duotone`

> two-colour map by luminance (CIColorMatrix)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `duotone=dark=#hex:light=#hex` |


## Example — red-panda, `fg:duotone=dark=#003366:light=#ffcc00` (subject filter, background preserved)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:duotone=dark=#003366:light=#ffcc00" -o red-panda-duotone.jpg
```

![red-panda after `fg:duotone=dark=#003366:light=#ffcc00`](../images/filters/duotone.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:duotone"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:duotone"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:duotone"
```

Panels (`original | bg | fg | all`):

![`duotone` panels on yoga](../images/filters/panels/yoga-duotone.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:duotone"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:duotone"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:duotone"
```

Panels (`original | bg | fg | all`):

![`duotone` panels on woman-singer](../images/filters/panels/woman-singer-duotone.jpg)

See the [filter index](README.md) for the full catalogue.
