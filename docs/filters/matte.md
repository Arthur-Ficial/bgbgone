# `matte`

> emit the alpha mask itself as final RGBA

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `matte` |
| **Note** | introduces alpha — output here is JPEG over the source bg; use `-o out.png` for true transparent output |

## Example — red-panda, `fg:matte` (subject filter, background preserved)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:matte" -o red-panda-matte.jpg
```

![red-panda after `fg:matte`](../images/filters/matte.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:matte"
```

Panels (`original | bg | fg | all`):

![`matte` panels on yoga](../images/filters/panels/yoga-matte.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:matte"
```

Panels (`original | bg | fg | all`):

![`matte` panels on woman-singer](../images/filters/panels/woman-singer-matte.jpg)

See the [filter index](README.md) for the full catalogue.
