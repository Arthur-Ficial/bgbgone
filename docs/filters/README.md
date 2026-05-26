# Filter catalogue (49 filters)

Every shipped filter, auto-generated from `bgbgone --filters-list --json`.
Tables grouped by valid-layer set; each row links to the per-filter doc
with paired before/after image.

## Tone + colour, spatial, stylise (`fg | bg | all`)

| Filter | Signature | One-liner |
|---|---|---|
| [`adjust`](adjust.md) | `adjust=brightness=B:contrast=C:saturation=S` | brightness/contrast/saturation in one call (CIColorControls) |
| [`blur`](blur.md) | `blur=radius` | Gaussian blur, radius in px (CIGaussianBlur) |
| [`box-blur`](box-blur.md) | `box-blur=radius` | box (mean) blur (CIBoxBlur) |
| [`colorize`](colorize.md) | `colorize=color=#hex:amount=A` | monochrome at a target colour (CIColorMonochrome) |
| [`comic`](comic.md) | `comic` | halftone comic-book effect (CIComicEffect) |
| [`crystallize`](crystallize.md) | `crystallize=radius` | Voronoi mosaic (CICrystallize) |
| [`desaturate`](desaturate.md) | `desaturate=amount` | scale saturation by 1-amount (CIColorControls) |
| [`duotone`](duotone.md) | `duotone=dark=#hex:light=#hex` | two-colour map by luminance (CIColorMatrix) |
| [`edge-work`](edge-work.md) | `edge-work=radius` | line-art edges (CIEdgeWork) |
| [`edges`](edges.md) | `edges=intensity` | edge detection (CIEdges) |
| [`emboss`](emboss.md) | `emboss` | raised relief via 3x3 convolution |
| [`exposure`](exposure.md) | `exposure=stops` | +/- stops, typical -2..+2 (CIExposureAdjust) |
| [`gamma`](gamma.md) | `gamma=value` | gamma curve, typical 0.5..2.5 (CIGammaAdjust) |
| [`grayscale`](grayscale.md) | `grayscale` | remove all colour saturation (CIColorControls) |
| [`hue`](hue.md) | `hue=degrees` | rotate hue by N degrees (CIHueAdjust) |
| [`levels`](levels.md) | `levels=black=B:white=W:gamma=G` | Photoshop-style levels (CIColorMatrix + CIGammaAdjust) |
| [`motion-blur`](motion-blur.md) | `motion-blur=radius:angle` | directional blur (CIMotionBlur) |
| [`negate`](negate.md) | `negate` | invert RGB (CIColorInvert) |
| [`noise`](noise.md) | `noise=amount` | additive film grain (CIRandomGenerator + composite) |
| [`opacity`](opacity.md) | `opacity=value` | scale alpha by value 0..1 (CIColorMatrix) |
| [`pixelate`](pixelate.md) | `pixelate=size` | block pixelation (CIPixellate) |
| [`pointillize`](pointillize.md) | `pointillize=radius` | Seurat dot effect (CIPointillize) |
| [`posterize`](posterize.md) | `posterize=levels` | quantise to N colour levels (CIColorPosterize) |
| [`sepia`](sepia.md) | `sepia=intensity` | warm-tinted monochrome 0..1 (CISepiaTone) |
| [`sharpen`](sharpen.md) | `sharpen=amount` | luminance sharpen (CISharpenLuminance) |
| [`temperature`](temperature.md) | `temperature=K` | shift colour temperature in Kelvin (CITemperatureAndTint) |
| [`tint`](tint.md) | `tint=color=#hex:amount=A` | blend toward a tint colour (CIColorMonochrome) |
| [`unsharp`](unsharp.md) | `unsharp=radius:intensity` | unsharp mask (CIUnsharpMask) |
| [`vibrance`](vibrance.md) | `vibrance=amount` | boost low-saturation colours (CIVibrance) |
| [`zoom-blur`](zoom-blur.md) | `zoom-blur=center=X,Y:amount=A` | radial zoom blur (CIZoomBlur) |

## Composite (`composite:`)

| Filter | Signature | One-liner |
|---|---|---|
| [`bloom`](bloom.md) | `bloom=intensity:radius` | soft glow on highlights, composite only (CIBloom) |
| [`gloom`](gloom.md) | `gloom=intensity:radius` | dark-glow inverse of bloom, composite only (CIGloom) |
| [`vignette`](vignette.md) | `vignette=intensity:radius` | darken edges, composite only (CIVignette) |
| [`vignette-effect`](vignette-effect.md) | `vignette-effect=center=X,Y:radius=R:intensity=I` | positioned vignette, composite only (CIVignetteEffect) |

## Foreground-only (`fg:`)

| Filter | Signature | One-liner |
|---|---|---|
| [`cutout`](cutout.md) | `cutout` | subject becomes a hole; background stays |
| [`flip`](flip.md) | `flip=horizontal|vertical` | mirror subject (CIAffineTransform) |
| [`glow`](glow.md) | `glow=color=#hex:radius=R:intensity=I` | subject glow halo (blur+tint+composite) |
| [`inner-shadow`](inner-shadow.md) | `inner-shadow=blur=B:offset=X,Y:opacity=O:color=#hex` | shadow inside the matte (invert+blur+intersect+tint) |
| [`matte`](matte.md) | `matte` | emit the alpha mask itself as final RGBA |
| [`outline`](outline.md) | `outline=color=#hex:width=N` | coloured outline outside the matte (morphology+subtract+tint) |
| [`rotate`](rotate.md) | `rotate=degrees` | rotate subject around centre (CIAffineTransform) |
| [`scale`](scale.md) | `scale=factor` | scale subject around centre (CIAffineTransform) |
| [`shadow`](shadow.md) | `shadow=blur=B:offset=X,Y:opacity=O:color=#hex` | per-subject drop shadow (translate+blur+tint+composite) |
| [`silhouette`](silhouette.md) | `silhouette=color=#hex` | fill the subject with one colour |
| [`translate`](translate.md) | `translate=dx,dy` | shift subject in pixels (CIAffineTransform) |

## Mask-shape (`mask:`)

| Filter | Signature | One-liner |
|---|---|---|
| [`contract`](contract.md) | `contract=pixels` | shrink matte erosion (CIMorphologyMinimum) |
| [`expand`](expand.md) | `expand=pixels` | grow matte dilation (CIMorphologyMaximum) |
| [`feather`](feather.md) | `feather=radius` | soften matte edge (CIGaussianBlur on mask) |
| [`threshold`](threshold.md) | `threshold=value` | binarise matte (CIColorThreshold) |

## Grammar

```
--filter "<layer>:<filter>[=args][,<filter>[=args]]...[;<layer>:...]"
```

- `<layer>` is one of `bg` `fg` `all` `composite` `mask` depending on the
  filter (see tables above).
- Filters in the same stage run left-to-right.
- A `;` introduces a new stage.
- A trailing `composite:` stage runs after the foreground/background split is
  flattened — only `vignette`, `vignette-effect`, `bloom`, `gloom` accept it.

Run `bgbgone --filters-list` (text) or `bgbgone --filters-list --json`
(machine-readable) for the live catalogue, or `bgbgone --help filter=<name>`
for one filter's full schema.
