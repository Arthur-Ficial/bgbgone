# `contract`

> shrink matte erosion (CIMorphologyMinimum)

| Field | Value |
|---|---|
| **Layers** | mask |
| **Signature** | `contract=pixels` |


## Example — red-panda

Original input:

![red-panda input](../../Tests/fixtures/red-panda.jpg)

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "mask:contract=3" -o red-panda-contract.jpg
```

After `mask:contract=3`:

![red-panda after mask:contract=3](../images/filters/contract.jpg)


## Per-layer panels — yoga (`--type person`)

Original input:

![yoga input](../../Tests/fixtures/yoga.jpg)

```bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "mask:contract"
```

Panels (`original | bg | fg | all`):

![`contract` panels on yoga](../images/filters/panels/yoga-contract.jpg)
## Per-layer panels — woman-singer (`--type person`)

Original input:

![woman-singer input](../../Tests/fixtures/woman-singer.jpg)

```bash
bgbgone woman-singer.jpg --type person --bg color:#1a2233 --filter "mask:contract"
```

Panels (`original | bg | fg | all`):

![`contract` panels on woman-singer](../images/filters/panels/woman-singer-contract.jpg)

See the [filter index](README.md) for the full catalogue.
