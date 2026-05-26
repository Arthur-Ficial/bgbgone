# `sharpen`

> luminance sharpen (CISharpenLuminance)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `sharpen=amount` |


## Example — red-panda, `fg:sharpen=0.5` (subject filter, background preserved)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:sharpen=0.5" -o red-panda-sharpen.jpg
```

![red-panda after `fg:sharpen=0.5`](../images/filters/sharpen.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:sharpen"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:sharpen"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:sharpen"
```

Panels (`original | bg | fg | all`):

![`sharpen` panels on yoga](../images/filters/panels/yoga-sharpen.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:sharpen"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:sharpen"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:sharpen"
```

Panels (`original | bg | fg | all`):

![`sharpen` panels on woman-singer](../images/filters/panels/woman-singer-sharpen.jpg)

See the [filter index](README.md) for the full catalogue.
