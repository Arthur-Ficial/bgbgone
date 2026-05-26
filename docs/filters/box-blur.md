# `box-blur`

> box (mean) blur (CIBoxBlur)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `box-blur=radius` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:box-blur=15" -o red-panda-box-blur.jpg
```

After `all:box-blur=15`:

![red-panda after all:box-blur=15](../images/filters/box-blur.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:box-blur"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:box-blur"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:box-blur"
```

Panels (`original | bg | fg | all`):

![`box-blur` panels on yoga](../images/filters/panels/yoga-box-blur.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:box-blur"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:box-blur"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:box-blur"
```

Panels (`original | bg | fg | all`):

![`box-blur` panels on woman-singer](../images/filters/panels/woman-singer-box-blur.jpg)

See the [filter index](README.md) for the full catalogue.
