# `shadow`

> per-subject drop shadow (translate+blur+tint+composite)

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `shadow=blur=B:offset=X,Y:opacity=O:color=#hex` |
| **Note** | introduces alpha — use PNG output or pass `--bg` |

## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:shadow=blur=12:offset=4,4:opacity=0.5:color=#000" -o red-panda-shadow.jpg
```

After `fg:shadow=blur=12:offset=4,4:opacity=0.5:color=#000`:

![red-panda after fg:shadow=blur=12:offset=4,4:opacity=0.5:color=#000](../images/filters/shadow.jpg)


## Per-layer panels — yoga (`--type person`)

Original input:

![yoga input](../../Tests/fixtures/yoga.jpg)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:shadow"
```

Panels (`original | bg | fg | all`):

![`shadow` panels on yoga](../images/filters/panels/yoga-shadow.jpg)
## Per-layer panels — woman-singer (`--type person`)

Original input:

![woman-singer input](../../Tests/fixtures/woman-singer.jpg)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:shadow"
```

Panels (`original | bg | fg | all`):

![`shadow` panels on woman-singer](../images/filters/panels/woman-singer-shadow.jpg)

See the [filter index](README.md) for the full catalogue.
