# `motion-blur`

> directional blur (CIMotionBlur)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `motion-blur=radius:angle` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:motion-blur=radius=10:angle=45" -o red-panda-motion-blur.jpg
```

After `all:motion-blur=radius=10:angle=45`:

![red-panda after all:motion-blur=radius=10:angle=45](../images/filters/motion-blur.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:motion-blur"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:motion-blur"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:motion-blur"
```

Panels (`original | bg | fg | all`):

![`motion-blur` panels on yoga](../images/filters/panels/yoga-motion-blur.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:motion-blur"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:motion-blur"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:motion-blur"
```

Panels (`original | bg | fg | all`):

![`motion-blur` panels on woman-singer](../images/filters/panels/woman-singer-motion-blur.jpg)

See the [filter index](README.md) for the full catalogue.
