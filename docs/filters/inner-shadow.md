# `inner-shadow`

> shadow inside the matte (invert+blur+intersect+tint)

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `inner-shadow=blur=B:offset=X,Y:opacity=O:color=#hex` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:inner-shadow=blur=12:offset=4,4:opacity=0.5:color=#000"
```

![`fg:inner-shadow=blur=12:offset=4,4:opacity=0.5:color=#000` on red-panda](../images/filters/inner-shadow.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg color:#1a2233 --filter "fg:inner-shadow=blur=12:offset=4,4:opacity=0.5:color=#000"
```

![`inner-shadow` panels on yoga](../images/filters/panels/yoga-inner-shadow.jpg)
![`inner-shadow` panels on woman-singer](../images/filters/panels/woman-singer-inner-shadow.jpg)

See the [filter index](README.md) for the full catalogue.
