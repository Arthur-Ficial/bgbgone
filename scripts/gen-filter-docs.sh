#!/bin/bash
# Generate docs/filters/<name>.md for every filter in the catalogue.
# Each MD references the matching docs/images/filters/<name>.jpg (single
# render) AND the per-subject layer-comparison panels under panels/.
# Separator is `^` (NOT `|`) because `|` is a legal char inside filter
# signatures (e.g. flip=horizontal|vertical).

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOCS="$ROOT/docs/filters"
mkdir -p "$DOCS"

# Format: name ^ category ^ layers-kind ^ signature ^ backing ^ chain-example ^ one-liner
# layers-kind: "all" / "composite-only" / "fg-only" / "mask-only"
ROWS=$(cat <<'EOF'
grayscale^tone+colour^all^grayscale^CIColorControls inputSaturation=0^bg:grayscale^Remove all colour saturation on the chosen layer.
desaturate^tone+colour^all^desaturate=amount^CIColorControls inputSaturation=1-amount^bg:desaturate=0.8^Partial desaturation - 0 keeps colour, 1 equals grayscale.
negate^tone+colour^all^negate^CIColorInvert^bg:negate^Invert RGB - black becomes white, blues become orange.
sepia^tone+colour^all^sepia=intensity^CISepiaTone^all:sepia=0.85^Warm monochrome tint, classic vintage look.
adjust^tone+colour^all^adjust=brightness=B:contrast=C:saturation=S^CIColorControls (3 params)^bg:adjust=brightness=-0.1:contrast=1.2:saturation=0.5^Brightness / contrast / saturation in one filter call.
gamma^tone+colour^all^gamma=value^CIGammaAdjust inputPower^bg:gamma=1.8^Gamma curve - <1 lightens, >1 darkens midtones.
exposure^tone+colour^all^exposure=stops^CIExposureAdjust inputEV^bg:exposure=0.8^Photographic stops, additive to current exposure.
hue^tone+colour^all^hue=degrees^CIHueAdjust inputAngle (radians)^bg:hue=90^Rotate hue around the colour wheel.
tint^tone+colour^all^tint=color=#hex:amount=A^CIColorMonochrome at lower intensity^bg:tint=color=#ff00ff:amount=0.5^Blend toward a tint colour.
colorize^tone+colour^all^colorize=color=#hex:amount=A^CIColorMonochrome^bg:colorize=color=#00bfff:amount=0.9^Map every pixel to a tone of one colour.
temperature^tone+colour^all^temperature=K^CITemperatureAndTint^bg:temperature=3500^Colour temperature shift in Kelvin.
levels^tone+colour^all^levels=black=B:white=W:gamma=G^CIColorMatrix + CIGammaAdjust^bg:levels=black=0.1:white=0.9:gamma=1.2^Photoshop-style levels remap.
vibrance^tone+colour^all^vibrance=amount^CIVibrance^all:vibrance=0.8^Saturation boost that protects already-saturated pixels.
opacity^tone+colour^all^opacity=value^CIColorMatrix alpha vector^bg:opacity=0.5^Scale alpha by value 0..1.
duotone^tone+colour^all^duotone=dark=#hex:light=#hex^CIColorMatrix on luminance^bg:duotone=dark=#003366:light=#ffcc00^Two-colour map of luminance.
blur^spatial^all^blur=radius^CIGaussianBlur^bg:blur=22^Gaussian blur, radius in pixels.
box-blur^spatial^all^box-blur=radius^CIBoxBlur^bg:box-blur=14^Box (mean) blur - flatter falloff than Gaussian.
motion-blur^spatial^all^motion-blur=radius:angle^CIMotionBlur^bg:motion-blur=radius=22:angle=45^Directional blur to simulate motion.
zoom-blur^spatial^all^zoom-blur=center=X,Y:amount=A^CIZoomBlur^bg:zoom-blur=center=0.5,0.5:amount=35^Radial zoom blur outward from a centre.
sharpen^spatial^all^sharpen=amount^CISharpenLuminance^all:sharpen=0.8^Luminance sharpen.
unsharp^spatial^all^unsharp=radius:intensity^CIUnsharpMask^all:unsharp=radius=3:intensity=1.0^Classic unsharp mask.
posterize^stylise^all^posterize=levels^CIColorPosterize^all:posterize=4^Quantise to N colour levels per channel.
pixelate^stylise^all^pixelate=size^CIPixellate^bg:pixelate=25^Block pixelation.
edges^stylise^all^edges=intensity^CIEdges^all:edges=2.5^Edge detection.
edge-work^stylise^all^edge-work=radius^CIEdgeWork^all:edge-work=3^Line-art edges with adjustable line weight.
emboss^stylise^all^emboss^CIConvolution3X3 with emboss kernel^all:emboss^Raised relief.
crystallize^stylise^all^crystallize=radius^CICrystallize^bg:crystallize=30^Voronoi-cell colour mosaic.
pointillize^stylise^all^pointillize=radius^CIPointillize^bg:pointillize=15^Seurat-style dot pattern.
comic^stylise^all^comic^CIComicEffect^all:comic^Halftone comic-book line treatment.
noise^stylise^all^noise=amount^CIRandomGenerator + CISourceOverCompositing^all:noise=0.3^Additive film grain.
vignette^composite^composite-only^vignette=intensity:radius^CIVignette^composite:vignette=2:1^Darken the edges. Composite-only.
vignette-effect^composite^composite-only^vignette-effect=center=X,Y:radius=R:intensity=I^CIVignetteEffect^composite:vignette-effect=center=0.5,0.5:radius=1.2:intensity=1.5^Positioned vignette with explicit centre.
bloom^composite^composite-only^bloom=intensity:radius^CIBloom^composite:bloom=1.0:18^Soft glow on highlights.
gloom^composite^composite-only^gloom=intensity:radius^CIGloom^composite:gloom=1.0:18^Inverse of bloom - softens shadows.
outline^mask-aware fg^fg-only^outline=color=#hex:width=N^CIMorphologyMaximum + subtract + tint composite^fg:outline=color=#ffaa00:width=6^Coloured outline just outside the matte boundary.
glow^mask-aware fg^fg-only^glow=color=#hex:radius=R:intensity=I^CIGaussianBlur on mask + tint + composite^fg:glow=color=#ffff80:radius=25:intensity=0.8^Soft glow halo around the subject.
shadow^mask-aware fg^fg-only^shadow=blur=B:offset=X,Y:opacity=O:color=#hex^Translate+blur+tint mask compose^fg:shadow=blur=14:offset=6,6:opacity=0.6:color=#000^Per-subject drop shadow.
inner-shadow^mask-aware fg^fg-only^inner-shadow=blur=B:offset=X,Y:opacity=O:color=#hex^Invert+blur+intersect+tint^fg:inner-shadow=blur=10:offset=2,2:opacity=0.7:color=#000^Shadow inside the matte for depth.
silhouette^mask-aware fg^fg-only^silhouette=color=#hex^CIConstantColorGenerator masked^fg:silhouette=color=#005577^Fill the subject with one colour.
cutout^mask-aware fg^fg-only^cutout^Invert mask^fg:cutout^Subject becomes a transparent hole; background stays.
matte^mask-aware fg^fg-only^matte^Emit alpha mask as RGBA^fg:matte^Output the alpha mask itself.
scale^geometric^fg-only^scale=factor^CIAffineTransform around centre^fg:scale=0.7^Scale subject around its centre.
translate^geometric^fg-only^translate=dx,dy^CIAffineTransform translation^fg:translate=120,-60^Shift subject in pixels.
rotate^geometric^fg-only^rotate=degrees^CIAffineTransform around centre^fg:rotate=15^Rotate subject around its centre.
flip^geometric^fg-only^flip=horizontal|vertical^CIAffineTransform mirror^fg:flip=horizontal^Mirror subject horizontally or vertically.
feather^mask-shape^mask-only^feather=radius^CIGaussianBlur on mask^mask:feather=8^Soften matte edge.
threshold^mask-shape^mask-only^threshold=value^CIColorThreshold^mask:threshold=0.5^Binarise matte at the chosen value.
expand^mask-shape^mask-only^expand=pixels^CIMorphologyMaximum on mask^mask:expand=4^Grow matte by N pixels (dilation).
contract^mask-shape^mask-only^contract=pixels^CIMorphologyMinimum on mask^mask:contract=4^Shrink matte by N pixels (erosion).
EOF
)

count=0
echo "$ROWS" | while IFS='^' read -r name category layers signature backing chain doc; do
    [ -z "$name" ] && continue
    out="$DOCS/${name}.md"

    case "$layers" in
        all)
            layer_block=$(cat <<INNER
\`\`\`bash
bgbgone yoga.jpg --type person --filter "bg:${name}"
bgbgone yoga.jpg --type person --filter "fg:${name}"
bgbgone yoga.jpg --type person --filter "all:${name}"
\`\`\`
INNER
)
            layers_human="fg / bg / all"
            ;;
        composite-only)
            layer_block=$(cat <<INNER
\`\`\`bash
bgbgone yoga.jpg --type person --filter "composite:${name}"
\`\`\`
INNER
)
            layers_human="composite only"
            ;;
        fg-only)
            layer_block=$(cat <<INNER
\`\`\`bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "fg:${name}"
\`\`\`
INNER
)
            layers_human="fg only"
            ;;
        mask-only)
            layer_block=$(cat <<INNER
\`\`\`bash
bgbgone yoga.jpg --type person --bg color:#1a2233 --filter "mask:${name}"
\`\`\`
INNER
)
            layers_human="mask only"
            ;;
        *)
            layer_block=""
            layers_human="$layers"
            ;;
    esac

    cat > "$out" <<MD
# \`${name}\`

> ${doc}

| Field | Value |
|---|---|
| **Category** | ${category} |
| **Valid layers** | ${layers_human} |
| **Signature** | \`${signature}\` |
| **Backed by** | ${backing} |

## Example

\`\`\`bash
bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "${chain}"
\`\`\`

| Baseline | After \`${chain}\` |
|---|---|
| ![baseline](../images/filters/_baseline.jpg) | ![${name}](../images/filters/${name}.jpg) |

Asset regenerated by [\`scripts/make-filter-showcase.sh\`](../../scripts/make-filter-showcase.sh) against the [Red Panda fixture (CC0)](../../Tests/fixtures/red-panda.jpg).

## Layer comparison — yoga (\`--type person\`)

Same filter on the valid layer(s), subject isolated via Apple Vision's person-segmentation model so neighbouring yogis don't interfere.

${layer_block}

![${name} on yoga](../images/filters/panels/yoga-${name}.jpg)

## Layer comparison — woman-singer Ahmadi (\`--type person\`)

Same chain against the [woman-singer Ahmadi portrait (CC0, Wikimedia Commons)](https://commons.wikimedia.org/wiki/File:woman-singer.jpg) — different lighting, different background detail, same per-layer behaviour.

![${name} on woman-singer](../images/filters/panels/woman-singer-${name}.jpg)

Panels regenerated by [\`scripts/make-perfilter-panels.sh\`](../../scripts/make-perfilter-panels.sh) on every release.

## See also

- Filter index: [docs/filters/README.md](README.md)
- Composition rules: [composition.md](composition.md)
- Curated chains: [recipes.md](recipes.md)
- Grammar primer: \`bgbgone --help\` / \`bgbgone --filters-list\`
MD
    count=$((count + 1))
done

NUM=$(ls -1 "$DOCS"/*.md 2>/dev/null | grep -v -E '(README|recipes|composition|colour-spaces|perf)\.md$' | wc -l | tr -d ' ')
echo "wrote $NUM per-filter docs into $DOCS"
