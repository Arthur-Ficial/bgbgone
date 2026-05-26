# Filter audit notes - 2026-05-24

This file records hypotheses before controlled renders. Each hypothesis names
the fixture trait, the filter arguments, the expected pixel-level visible
change, and what must remain unchanged.

## Hypotheses

filter: outline
hypothesis: Given the corgi on a dark navy plate, `fg:outline=color=#ffaa00:width=10` should add an orange ring at pixels just outside the fur matte, while interior fur pixels and far-corner background pixels stay unchanged.

filter: glow
hypothesis: Given the corgi on a dark navy plate, `fg:glow=color=#ffff80:radius=25:intensity=0.8` should raise yellow luminance in a soft halo around the matte edge, while the subject face texture stays original.

filter: shadow
hypothesis: Given the corgi on a light neutral plate, `fg:shadow=blur=18:offset=28,28:opacity=0.7:color=#000` should darken pixels down-right of the matte and leave up-left background and subject fur unchanged.

filter: inner-shadow
hypothesis: Given the corgi on a dark navy plate, `fg:inner-shadow=blur=12:offset=8,8:opacity=0.75:color=#000` should darken pixels just inside the matte edge and leave exterior background pixels unchanged.

filter: cutout
hypothesis: Given the corgi on a dark navy plate, `fg:cutout` should show the navy plate through subject-body pixels and leave exterior background pixels navy.

filter: adjust
hypothesis: Given the red panda over its own forest background, `bg:adjust=brightness=-0.1:contrast=1.2:saturation=0.5` should darken/desaturate background foliage pixels, while red panda fur pixels stay original.

filter: bloom
hypothesis: Given the red panda composite with bright highlights, `composite:bloom=1.0:18` should expand highlight glow around bright leaves and fur highlights, while dark shadows change less.

filter: blur
hypothesis: Given the red panda over its own forest background, `bg:blur=22` should reduce local edge contrast in foliage pixels, while the red panda face remains sharp.

filter: box-blur
hypothesis: Given the red panda over its own forest background, `bg:box-blur=14` should flatten foliage texture with a mean-blur look, while the red panda face remains sharp.

filter: colorize
hypothesis: Given the red panda over its own forest background, `bg:colorize=color=#00bfff:amount=0.9` should map background foliage toward cyan monochrome, while red panda fur colour remains original.

filter: comic
hypothesis: Given the red panda composite, `all:comic` should add dark posterized linework across both subject and background, while the matte boundary remains aligned.

filter: contract
hypothesis: Given the red panda on a dark navy plate, `mask:contract=14` should shrink the visible subject edge inward by about 14 px, while far background stays navy.

filter: crystallize
hypothesis: Given the red panda over its own forest background, `bg:crystallize=30` should replace background foliage with visible polygonal cells, while the red panda remains natural.

filter: desaturate
hypothesis: Given the red panda over its own green forest background, `bg:desaturate=0.8` should strongly reduce background chroma but leave visible residual colour, while red panda fur stays orange.

filter: duotone
hypothesis: Given the red panda over its own forest background, `bg:duotone=dark=#003366:light=#ffcc00` should map background shadows blue and highlights yellow, while red panda fur stays original.

filter: edge-work
hypothesis: Given the red panda composite, `all:edge-work=3` should turn both subject and background into high-contrast line-art edges, while output geometry stays fixed.

filter: edges
hypothesis: Given the red panda composite, `all:edges=2.5` should emit bright edge contours on dark surroundings across subject and background, while flat regions become darker.

filter: emboss
hypothesis: Given the red panda composite, `all:emboss` should convert subject and background texture into raised gray relief with directional highlights, while dimensions and matte alignment stay fixed.

filter: expand
hypothesis: Given the red panda on a dark navy plate, `mask:expand=14` should grow the visible subject edge outward by about 14 px, while far background stays navy.

filter: exposure
hypothesis: Given the red panda over its own forest background, `bg:exposure=0.8` should brighten background foliage by roughly one photographic stop, while red panda fur stays original.

filter: feather
hypothesis: Given the red panda on a dark navy plate, `mask:feather=24` should create a soft semi-transparent edge over the navy plate, while subject interior and far background stay stable.

filter: flip
hypothesis: Given the red panda on a contrast plate, `fg:flip=horizontal` should mirror subject pixels left-right around canvas centre, while background pixels stay fixed.

filter: gamma
hypothesis: Given the red panda over its own forest background, `bg:gamma=1.8` should darken background midtones, while red panda fur stays original.

filter: gloom
hypothesis: Given the red panda composite, `composite:gloom=1.0:18` should spread darker soft glow through shadowed detail, while geometry and matte alignment stay fixed.

filter: grayscale
hypothesis: Given the red panda over its own green forest background, `bg:grayscale` should make background foliage pixels near-equal RGB, while red panda fur remains orange.

filter: hue
hypothesis: Given the red panda over its own forest background, `bg:hue=90` should rotate green foliage toward a different hue, while red panda fur stays original.

filter: levels
hypothesis: Given the red panda over its own forest background, `bg:levels=black=0.1:white=0.9:gamma=1.2` should increase background contrast and remap midtones, while red panda fur stays original.

filter: matte
hypothesis: Given the red panda on any plate, `fg:matte` should output a visible grayscale alpha mask where subject pixels are light and background pixels are dark, independent of source colour.

filter: motion-blur
hypothesis: Given the red panda over its own forest background, `bg:motion-blur=radius=22:angle=45` should smear background edges diagonally, while the red panda remains sharp.

filter: negate
hypothesis: Given the red panda over its own forest background, `bg:negate` should invert background RGB so greens become magenta/purple, while red panda fur stays original.

filter: noise
hypothesis: Given the red panda composite, `all:noise=0.3` should add fine luminance grain across both subject and background, while large colour structure remains recognizable.

filter: opacity
hypothesis: Given the red panda over its own background, `fg:opacity=0.5` should reduce foreground alpha so source background partially shows through subject pixels, while background pixels stay unchanged.

filter: pixelate
hypothesis: Given the red panda over its own forest background, `bg:pixelate=25` should turn background foliage into square blocks, while red panda fur remains detailed.

filter: pointillize
hypothesis: Given the red panda over its own forest background, `bg:pointillize=15` should turn background foliage into colored dots, while red panda fur remains natural.

filter: posterize
hypothesis: Given the red panda composite, `all:posterize=4` should reduce both subject and background to a small set of tone bands, while object boundaries stay aligned.

filter: rotate
hypothesis: Given the red panda on a contrast plate, `fg:rotate=15` should rotate subject pixels around canvas centre and reveal plate triangles at the moved matte edge, while background stays fixed.

filter: scale
hypothesis: Given the red panda on a contrast plate, `fg:scale=0.7` should shrink the subject around canvas centre and expose more background plate, while background stays fixed.

filter: sepia
hypothesis: Given the red panda composite, `all:sepia=0.85` should warm both subject and background toward brown monochrome, while dimensions and matte stay fixed.

filter: sharpen
hypothesis: Given the red panda composite, `all:sharpen=0.8` should increase local luminance edge contrast on fur and foliage, while flat background areas change little.

filter: silhouette
hypothesis: Given the red panda on a dark navy plate, `fg:silhouette=color=#005577` should fill the subject matte with teal and leave exterior background navy.

filter: temperature
hypothesis: Given the red panda over its own forest background, `bg:temperature=3500` should cool/warm-shift background colour temperature visibly, while red panda fur stays original.

filter: threshold
hypothesis: Given the red panda on a dark navy plate, `mask:threshold=0.5` should harden semi-transparent matte edges into a crisp binary boundary, while far subject and background pixels stay stable.

filter: tint
hypothesis: Given the red panda over its own forest background, `bg:tint=color=#ff00ff:amount=0.5` should pull background colours toward magenta, while red panda fur stays original.

filter: translate
hypothesis: Given the red panda on a contrast plate, `fg:translate=120,-60` should move subject pixels right and up by the requested offset, while background pixels stay fixed.

filter: unsharp
hypothesis: Given the red panda composite, `all:unsharp=radius=3:intensity=1.0` should increase fine edge contrast on fur and foliage, while dimensions and matte stay fixed.

filter: vibrance
hypothesis: Given the red panda composite, `all:vibrance=0.8` should boost muted colours more than already-saturated fur, while luminance structure stays recognizable.

filter: vignette
hypothesis: Given the red panda composite, `composite:vignette=2:1` should darken corner pixels more than central face pixels, while the subject/background layout stays fixed.

filter: vignette-effect
hypothesis: Given the red panda composite, `composite:vignette-effect=center=0.5,0.5:radius=1.2:intensity=1.5` should darken pixels outside a centred oval falloff, while central face pixels change less.

filter: zoom-blur
hypothesis: Given the red panda over its own forest background, `bg:zoom-blur=center=0.5,0.5:amount=35` should radially smear background texture away from centre, while the red panda remains sharp.
