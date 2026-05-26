# `cutout`

> subject becomes a hole; background stays

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `cutout` |
| **Note** | introduces alpha — output here is JPEG over the source bg; use `-o out.png` for true transparent output |

## Example — red-panda, `fg:cutout` (subject filter, background preserved)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:cutout" -o red-panda-cutout.jpg
```

![red-panda after `fg:cutout`](../images/filters/cutout.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:cutout"
```

Panels (`original | bg | fg | all`):

![`cutout` panels on yoga](../images/filters/panels/yoga-cutout.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:cutout"
```

Panels (`original | bg | fg | all`):

![`cutout` panels on woman-singer](../images/filters/panels/woman-singer-cutout.jpg)

See the [filter index](README.md) for the full catalogue.
