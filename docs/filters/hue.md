# `hue`

> rotate hue by N degrees (CIHueAdjust)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `hue=degrees` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:hue=120" -o red-panda-hue.jpg
```

After `all:hue=120`:

![red-panda after all:hue=120](../images/filters/hue.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:hue"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:hue"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:hue"
```

Panels (`original | bg | fg | all`):

![`hue` panels on yoga](../images/filters/panels/yoga-hue.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:hue"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:hue"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:hue"
```

Panels (`original | bg | fg | all`):

![`hue` panels on woman-singer](../images/filters/panels/woman-singer-hue.jpg)

See the [filter index](README.md) for the full catalogue.
