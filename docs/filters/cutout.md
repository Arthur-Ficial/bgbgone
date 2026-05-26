# `cutout`

> subject becomes a hole; background stays

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `cutout` |
| **Note** | introduces alpha — use PNG output or pass `--bg` |

## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:cutout" -o red-panda-cutout.jpg
```

After `fg:cutout`:

![red-panda after fg:cutout](../images/filters/cutout.jpg)


## Per-layer panels — yoga (`--type person`)

Original input:

![yoga input](../../Tests/fixtures/yoga.jpg)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:cutout"
```

Panels (`original | bg | fg | all`):

![`cutout` panels on yoga](../images/filters/panels/yoga-cutout.jpg)
## Per-layer panels — woman-singer (`--type person`)

Original input:

![woman-singer input](../../Tests/fixtures/woman-singer.jpg)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:cutout"
```

Panels (`original | bg | fg | all`):

![`cutout` panels on woman-singer](../images/filters/panels/woman-singer-cutout.jpg)

See the [filter index](README.md) for the full catalogue.
