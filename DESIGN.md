# quarto-chevrons

## Goal

Build reusable Quarto/Reveal.js components for circular flow diagrams. Clean Quarto div syntax:

```
::: circle-flow
::: item
Alice
:::
::: item
Bob
:::
:::
```

## Current state

Packaged as a Quarto extension in `_extensions/circle-flow/`:

- **`_extension.yml`** — declares the Lua filter; no format contributions (those are done in the filter)
- **`circle-flow.lua`** — injects CSS via `quarto.doc.add_html_dependency` and JS via `quarto.doc.include_file("after-body", ...)`. Only runs for HTML-based formats. Do NOT use `contributes.format` in `_extension.yml` for this — it only works for defining new formats, not adding to existing ones.
- **`circle-flow.css`** — plain CSS for `.circle-flow`, `.node`, `.arrow-shape`
- **`circle-flow.html`** — JS that reads `.item` divs, positions them in a circle, and draws arrows

Users activate with `filters: [circle-flow]` in their document YAML.

- **`index.qmd`** — Demo slides covering item counts, node shapes, arrow types, and colors

## How the JS works

`initCircleFlow(container)` runs on `DOMContentLoaded` and on Reveal.js `slidechanged`:
1. Detects `nodeType` (circle/box/none) and `arrowType` (chevron/curved/thin/ring/arc/double) from container classes
2. Reads `data-node-color`, `data-arrow-color` from container (via `dataset`); `color` from items (Pandoc auto-prefixes unknown attrs with `data-` but passes the legacy `color` attribute through)
3. Computes `layoutR` and `nodeRadius` from `n` (see sizing math below)
4. Creates `.node` divs positioned on the circle; sets size, background color, and border-radius inline
5. Scales font size via canvas `measureText` so the longest label fills (but doesn't overflow) the node
6. Renders arrows — chevrons as divs, all other types as SVG overlays inserted behind the nodes

## Design decisions

- **1 item → no arrow.** Arrow loop is skipped entirely.
- **2 items → side-by-side arrows.** Arrows are offset `nodeRadius * 0.3` perpendicular to the line between nodes so they don't overlap.
- **Font scaling uses canvas `measureText`.** `getBoundingClientRect` returns 0 for hidden Reveal slides; canvas works regardless. Falls back to `17.6px` if `getComputedStyle` returns 0.
- **`node-none` font size** is capped at a fixed 80px max width, independent of `nodeRadius`, so labels stay a consistent readable size regardless of `n`.
- **Node size and layout radius are computed from n.** Gap between neighboring circle edges = nodeRadius. Math: `nodeRadius = (2/3) · layoutR · sin(π/n)`, with `layoutR + nodeRadius ≤ 240`. For n=1: `layoutR=0`, `nodeRadius=240`.
- **`data-cf-init` guards double-init.** Both `DOMContentLoaded` and `slidechanged` set this so `initCircleFlow` never runs twice on the same container.
- **SVG arrows are inserted before node divs** (behind them in z-order). The nodes' solid backgrounds cover any SVG that passes through them.
- **`arrow-ring` uses an SVG mask** to cleanly hide the ring circle inside each node, rather than relying on node backgrounds to cover it.
- **`arrow-curved` and `arrow-arc` are filled SVG paths** (outer arc + inner arc + pointed tip). Do NOT use SVG stroke + `marker-end` — marker placement on curved paths is unreliable.

## Class system

Node and arrow styles are independent modifier classes on `.circle-flow`:

**Node classes** (default: `node-circle`):
- `node-circle` — filled circle; `border-radius: 50%` in CSS
- `node-box` — rounded rectangle; width = nodeRadius×1.8, height = nodeRadius×1.2, border-radius set proportionally in JS
- `node-none` — text only; transparent background, dark text; same layout math as circle

**Arrow classes** (default: `arrow-chevron`):
- `arrow-chevron` — div-based filled chevron shapes, scaled with nodeRadius
- `arrow-curved` — filled SVG arrow shapes (outer arc + inner arc + pointed tip) between each pair
- `arrow-thin` — SVG thin straight lines with arrowhead per pair
- `arrow-ring` — single SVG circle behind all nodes with mask to hide inside nodes
- `arrow-arc` — single filled SVG arrow shape going clockwise around all nodes
- `arrow-double` — SVG thin lines with arrowheads on both ends

SVG arrows use a unique `uid` per container to avoid marker ID collisions across slides.

## Color system

- `node-color="<color>"` on container — all nodes (default `#2e6b8a`)
- `color="<color>"` on an individual `.item` — overrides that node only
- `arrow-color="<color>"` on container — all arrows (default `#2e6b8a`)
- Source-side: write attributes without `data-` prefix. Pandoc rewrites unknown attrs to `data-*` in the HTML output, so the JS reads container attrs via `dataset.*`. `color` is a legacy HTML attribute and is passed through unprefixed.
- Arrow color is always global; no per-arrow color support
