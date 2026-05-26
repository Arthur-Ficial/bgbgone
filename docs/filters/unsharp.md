# `unsharp`

> unsharp mask (CIUnsharpMask)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `unsharp=radius:intensity` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:unsharp=radius=2.5:intensity=0.5" -o red-panda-unsharp.jpg
```

After `all:unsharp=radius=2.5:intensity=0.5`:

![red-panda after all:unsharp=radius=2.5:intensity=0.5](../images/filters/unsharp.jpg)


## Per-layer panels — yoga (`--type person`)

Original input:

![yoga input](../../Tests/fixtures/yoga.jpg)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:unsharp"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:unsharp"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:unsharp"
```

Panels (`original | bg | fg | all`):

![`unsharp` panels on yoga](../images/filters/panels/yoga-unsharp.jpg)
## Per-layer panels — woman-singer (`--type person`)

Original input:

![woman-singer input](../../Tests/fixtures/woman-singer.jpg)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:unsharp"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:unsharp"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:unsharp"
```

Panels (`original | bg | fg | all`):

![`unsharp` panels on woman-singer](../images/filters/panels/woman-singer-unsharp.jpg)

See the [filter index](README.md) for the full catalogue.
