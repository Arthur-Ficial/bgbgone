# `rotate`

> rotate subject around centre (CIAffineTransform)

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `rotate=degrees` |


## Example — red-panda, `fg:rotate=15` (subject filter, background preserved)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:rotate=15" -o red-panda-rotate.jpg
```

![red-panda after `fg:rotate=15`](../images/filters/rotate.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:rotate"
```

Panels (`original | bg | fg | all`):

![`rotate` panels on yoga](../images/filters/panels/yoga-rotate.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:rotate"
```

Panels (`original | bg | fg | all`):

![`rotate` panels on woman-singer](../images/filters/panels/woman-singer-rotate.jpg)

See the [filter index](README.md) for the full catalogue.
