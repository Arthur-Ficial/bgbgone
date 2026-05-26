# `blur`

> Gaussian blur, radius in px (CIGaussianBlur)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `blur=radius` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:blur=15" -o red-panda-blur.jpg
```

After `all:blur=15`:

![red-panda after all:blur=15](../images/filters/blur.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:blur"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:blur"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:blur"
```

Panels (`original | bg | fg | all`):

![`blur` panels on yoga](../images/filters/panels/yoga-blur.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:blur"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:blur"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:blur"
```

Panels (`original | bg | fg | all`):

![`blur` panels on woman-singer](../images/filters/panels/woman-singer-blur.jpg)

See the [filter index](README.md) for the full catalogue.
