# `silhouette`

> fill the subject with one colour

| Field | Value |
|---|---|
| **Layers** | fg |
| **Signature** | `silhouette=color=#hex` |


## Example — red-panda, `fg:silhouette=color=#ff0000` (subject filter, background preserved)

The same operation through both transports. `scripts/gen-docs.sh` executes BOTH commands on every regen and asserts the outputs are byte-identical (parity contract). The image below is the result.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "fg:silhouette=color=#ff0000" --size preview -o red-panda-silhouette.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=fg:silhouette=color=#ff0000" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-silhouette.jpg
```

![red-panda after `fg:silhouette=color=#ff0000` — CLI render = server render (byte-identical)](../images/filters/silhouette.jpg)



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

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
