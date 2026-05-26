# `contract`

> shrink matte erosion (CIMorphologyMinimum)

| Field | Value |
|---|---|
| **Layers** | mask |
| **Signature** | `contract=pixels` |


## Example

```bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "mask:contract=3"
```

![`mask:contract=3` on red-panda](../images/filters/contract.jpg)

## Per-layer panels

```bash
bgbgone red-panda.jpg --bg color:#1a2233 --filter "mask:contract=3"
```

![`contract` panels on yoga](../images/filters/panels/yoga-contract.jpg)
![`contract` panels on woman-singer](../images/filters/panels/woman-singer-contract.jpg)

See the [filter index](README.md) for the full catalogue.
