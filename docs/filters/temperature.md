# `temperature`

> shift colour temperature in Kelvin (CITemperatureAndTint)

| Field | Value |
|---|---|
| **Layers** | all, bg, fg |
| **Signature** | `temperature=K` |


## Example — red-panda, `fg:temperature=9000` (subject filter, background preserved)

The same operation through both transports. `scripts/gen-docs.sh` executes BOTH commands on every regen and asserts the outputs are byte-identical (parity contract). The image below is the result.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:temperature=9000" --size preview -o red-panda-temperature.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:temperature=9000" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-temperature.jpg
```

![red-panda after `fg:temperature=9000` — CLI render = server render (byte-identical)](../images/filters/temperature.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "bg:temperature=3500"
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:temperature=3500"
bgbgone yoga.jpg --type person --bg "image:yoga.jpg" --filter "all:temperature=3500"
```

Panels (`original | bg | fg | all`):

![`temperature` panels on yoga](../images/filters/panels/yoga-temperature.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "bg:temperature=3500"
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "fg:temperature=3500"
bgbgone woman-singer.jpg --type person --bg "image:woman-singer.jpg" --filter "all:temperature=3500"
```

Panels (`original | bg | fg | all`):

![`temperature` panels on woman-singer](../images/filters/panels/woman-singer-temperature.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
