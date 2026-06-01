# `contract`

> shrink matte erosion (CIMorphologyMinimum)

| Field | Value |
|---|---|
| **Layers** | mask |
| **Signature** | `contract=pixels` |


## Example — `mask:contract=3`

The same operation through both transports. `scripts/gen-docs.sh` runs BOTH commands on every regen and asserts byte-identical output (parity contract). The result is shown below.

### Via CLI

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "mask:contract=3" --size preview -o red-panda-contract.jpg
```

### Via HTTP server (`bgbgone --server`)

```bash
curl -X POST http://127.0.0.1:8787/bgbgone \
  -F "image_file=@red-panda.jpg" \
  -F "bg=@red-panda.jpg" \
  -F "filter=mask:contract=3" \
  -F "format=jpg" \
  -F "size=preview" \
  -o red-panda-contract.jpg
```

![red-panda after `mask:contract=3` — CLI render = server render (byte-identical)](../images/filters/contract.jpg)



## Per-layer panels — yoga (`--type person`)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "mask:contract=14"
```

Panels (`original | bg | fg | all`):

![`contract` panels on yoga](../images/filters/panels/yoga-contract.jpg)

## Per-layer panels — woman-singer (`--type person`)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "mask:contract=14"
```

Panels (`original | bg | fg | all`):

![`contract` panels on woman-singer](../images/filters/panels/woman-singer-contract.jpg)

See the [filter index](README.md) for the full catalogue. Server-mode README: [`../../SERVER-README.md`](../../SERVER-README.md).
