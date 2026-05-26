# `silhouette`

> fill the subject with one colour

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `silhouette=color=#hex` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:silhouette=color=#ff0000" -o red-panda-silhouette.jpg
```

After `fg:silhouette=color=#ff0000`:

![red-panda after fg:silhouette=color=#ff0000](../images/filters/silhouette.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:silhouette"
```

Panels (`original | bg | fg | all`):

![`silhouette` panels on yoga](../images/filters/panels/yoga-silhouette.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:silhouette"
```

Panels (`original | bg | fg | all`):

![`silhouette` panels on woman-singer](../images/filters/panels/woman-singer-silhouette.jpg)

See the [filter index](README.md) for the full catalogue.
