# `flip`

> mirror subject (CIAffineTransform)

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `flip=horizontal|vertical` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:flip=horizontal" -o red-panda-flip.jpg
```

After `fg:flip=horizontal`:

![red-panda after fg:flip=horizontal](../images/filters/flip.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:flip"
```

Panels (`original | bg | fg | all`):

![`flip` panels on yoga](../images/filters/panels/yoga-flip.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:flip"
```

Panels (`original | bg | fg | all`):

![`flip` panels on woman-singer](../images/filters/panels/woman-singer-flip.jpg)

See the [filter index](README.md) for the full catalogue.
