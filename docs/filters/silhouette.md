# `silhouette`

> fill the subject with one colour

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `silhouette=color=#hex` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:silhouette=color=#ff0000"
```

![`fg:silhouette=color=#ff0000` on red-panda](../images/filters/silhouette.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:silhouette=color=#ff0000"
```

![`silhouette` panels on yoga](../images/filters/panels/yoga-silhouette.jpg)
![`silhouette` panels on woman-singer](../images/filters/panels/woman-singer-silhouette.jpg)

See the [filter index](README.md) for the full catalogue.
