# `desaturate`

> scale saturation by 1-amount (CIColorControls)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `desaturate=amount` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:desaturate=0.5" -o red-panda-desaturate.jpg
```

After `all:desaturate=0.5`:

![red-panda after all:desaturate=0.5](../images/filters/desaturate.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:desaturate"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:desaturate"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:desaturate"
```

Panels (`original | bg | fg | all`):

![`desaturate` panels on yoga](../images/filters/panels/yoga-desaturate.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:desaturate"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:desaturate"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:desaturate"
```

Panels (`original | bg | fg | all`):

![`desaturate` panels on woman-singer](../images/filters/panels/woman-singer-desaturate.jpg)

See the [filter index](README.md) for the full catalogue.
