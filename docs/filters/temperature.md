# `temperature`

> shift colour temperature in Kelvin (CITemperatureAndTint)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `temperature=K` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "all:temperature=6500" -o red-panda-temperature.jpg
```

After `all:temperature=6500`:

![red-panda after all:temperature=6500](../images/filters/temperature.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:temperature"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:temperature"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:temperature"
```

Panels (`original | bg | fg | all`):

![`temperature` panels on yoga](../images/filters/panels/yoga-temperature.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:temperature"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:temperature"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:temperature"
```

Panels (`original | bg | fg | all`):

![`temperature` panels on woman-singer](../images/filters/panels/woman-singer-temperature.jpg)

See the [filter index](README.md) for the full catalogue.
