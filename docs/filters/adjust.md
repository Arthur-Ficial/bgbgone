# `adjust`

> brightness/contrast/saturation in one call (CIColorControls)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `adjust=brightness=B:contrast=C:saturation=S` |


## Example — red-panda, `fg:adjust=brightness=0.1:contrast=1.1:saturation=0.9` (subject filter, background preserved)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:adjust=brightness=0.1:contrast=1.1:saturation=0.9" -o red-panda-adjust.jpg
```

![red-panda after `fg:adjust=brightness=0.1:contrast=1.1:saturation=0.9`](../images/filters/adjust.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:adjust"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:adjust"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:adjust"
```

Panels (`original | bg | fg | all`):

![`adjust` panels on yoga](../images/filters/panels/yoga-adjust.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:adjust"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:adjust"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:adjust"
```

Panels (`original | bg | fg | all`):

![`adjust` panels on woman-singer](../images/filters/panels/woman-singer-adjust.jpg)

See the [filter index](README.md) for the full catalogue.
