# `zoom-blur`

> radial zoom blur (CIZoomBlur)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `zoom-blur=center=X,Y:amount=A` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:zoom-blur=center=0.5,0.5:amount=20" -o red-panda-zoom-blur.jpg
```

After `all:zoom-blur=center=0.5,0.5:amount=20`:

![red-panda after all:zoom-blur=center=0.5,0.5:amount=20](../images/filters/zoom-blur.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:zoom-blur"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:zoom-blur"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:zoom-blur"
```

Panels (`original | bg | fg | all`):

![`zoom-blur` panels on yoga](../images/filters/panels/yoga-zoom-blur.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:zoom-blur"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:zoom-blur"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:zoom-blur"
```

Panels (`original | bg | fg | all`):

![`zoom-blur` panels on woman-singer](../images/filters/panels/woman-singer-zoom-blur.jpg)

See the [filter index](README.md) for the full catalogue.
