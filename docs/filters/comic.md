# `comic`

> halftone comic-book effect (CIComicEffect)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `comic` |


## Example — red-panda, `fg:comic` (subject filter, background preserved)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:comic" -o red-panda-comic.jpg
```

![red-panda after `fg:comic`](../images/filters/comic.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:comic"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:comic"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:comic"
```

Panels (`original | bg | fg | all`):

![`comic` panels on yoga](../images/filters/panels/yoga-comic.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:comic"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:comic"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:comic"
```

Panels (`original | bg | fg | all`):

![`comic` panels on woman-singer](../images/filters/panels/woman-singer-comic.jpg)

See the [filter index](README.md) for the full catalogue.
