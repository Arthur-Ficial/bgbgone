# `matte`

> emit the alpha mask itself as final RGBA

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `matte` |
| **Note** | introduces alpha — use PNG output or pass `--bg` |

## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:matte" -o red-panda-matte.jpg
```

After `fg:matte`:

![red-panda after fg:matte](../images/filters/matte.jpg)


## Per-layer panels — yoga (`--type person`)

Original input:

![yoga input](../../Tests/fixtures/yoga.jpg)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:matte"
```

Panels (`original | bg | fg | all`):

![`matte` panels on yoga](../images/filters/panels/yoga-matte.jpg)
## Per-layer panels — woman-singer (`--type person`)

Original input:

![woman-singer input](../../Tests/fixtures/woman-singer.jpg)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:matte"
```

Panels (`original | bg | fg | all`):

![`matte` panels on woman-singer](../images/filters/panels/woman-singer-matte.jpg)

See the [filter index](README.md) for the full catalogue.
