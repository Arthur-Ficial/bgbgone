# `sepia`

> warm-tinted monochrome 0..1 (CISepiaTone)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `sepia=intensity` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:sepia=0.8" -o red-panda-sepia.jpg
```

After `all:sepia=0.8`:

![red-panda after all:sepia=0.8](../images/filters/sepia.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:sepia"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:sepia"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:sepia"
```

Panels (`original | bg | fg | all`):

![`sepia` panels on yoga](../images/filters/panels/yoga-sepia.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:sepia"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:sepia"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:sepia"
```

Panels (`original | bg | fg | all`):

![`sepia` panels on woman-singer](../images/filters/panels/woman-singer-sepia.jpg)

See the [filter index](README.md) for the full catalogue.
