# `outline`

> coloured outline outside the matte (morphology+subtract+tint)

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `outline=color=#hex:width=N` |
| **Note** | introduces alpha — use PNG output or pass `--bg` |

## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:outline=color=#ffffff:width=3" -o red-panda-outline.jpg
```

After `fg:outline=color=#ffffff:width=3`:

![red-panda after fg:outline=color=#ffffff:width=3](../images/filters/outline.jpg)


## Per-layer panels — yoga (`--type person`)

Original input:

![yoga input](../../Tests/fixtures/yoga.jpg)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:outline"
```

Panels (`original | bg | fg | all`):

![`outline` panels on yoga](../images/filters/panels/yoga-outline.jpg)
## Per-layer panels — woman-singer (`--type person`)

Original input:

![woman-singer input](../../Tests/fixtures/woman-singer.jpg)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:outline"
```

Panels (`original | bg | fg | all`):

![`outline` panels on woman-singer](../images/filters/panels/woman-singer-outline.jpg)

See the [filter index](README.md) for the full catalogue.
