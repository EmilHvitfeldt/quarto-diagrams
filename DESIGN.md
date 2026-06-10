# quarto-diagrams

## Goal

Build reusable Quarto/Reveal.js diagram components. Ten layouts are provided: `.circle-flow` (nodes-on-a-ring with arrows), `.pie` (pie chart), `.process` (linear flow), `.pyramid` (stacked triangle bands), `.matrix` (2×2 quadrant matrix), `.hierarchy` (org chart / tree), `.venn` (2- or 3-set overlapping circles), `.stacked-venn` (nested concentric circles), `.funnel` (flat-bottomed narrowing stages, optionally sized by `value=`), and `.cycle` (ring of arc-shaped arrow segments). Clean Quarto div syntax:

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

Packaged as a Quarto extension in `_extensions/diagrams/`:

- **`_extension.yml`** — declares the Lua filter; no format contributions (those are done in the filter)
- **`diagrams.lua`** — injects CSS via `quarto.doc.add_html_dependency` and JS via `quarto.doc.include_file("after-body", ...)`. Only runs for HTML-based formats. Do NOT use `contributes.format` in `_extension.yml` for this — it only works for defining new formats, not adding to existing ones.
- **`diagrams.css`** — plain CSS for `.circle-flow`, `.node`, `.arrow-shape`
- **`diagrams.html`** — JS that reads `.item` divs, positions them in a circle, and draws arrows

Users activate with `filters: [diagrams]` in their document YAML.

- **`index.qmd`** — Demo slides covering item counts, node shapes, arrow types, and colors

## Limitations

- **Items are plain text only.** All layouts read `item.textContent.trim()`, so any rich markup inside an `.item` (bold, links, math, images) is flattened to plain text.

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

## Pie layout

A separate layout, triggered by `.pie` on the container (instead of `.circle-flow`). Items become pie slices instead of nodes-on-a-ring. Implemented by `initPie` in `diagrams.html`, with CSS for `.pie` and `.slice-label` in `diagrams.css`.

```
::: pie
::: item
Alice
:::
::: item
Bob
:::
:::
```

**Class system:**
- `.pie` on container — pie chart layout
- `.gap` on container — separate all slices with an offset, no white stroke
- `.gap` on an individual `.item` — offset just that slice (keeps the white stroke on others)
- `.donut` on container — hollow center (ring); `hole=` sets the inner-radius fraction (default `0.55`, clamped `0.2`–`0.85`), `center=` places a label in the hole
- `.arrow` on container — donut sub-variant (implies `.donut`): each segment's radial edges are chevrons advanced forward by `tip = min(0.13, span·0.32)` rad at the mid radius, with an angular half-gap `gapA = min(0.05, span·0.18)` each side. The leading edge forms a clockwise arrowhead, the trailing edge a matching notch, and the gap leaves a uniform arrow-shaped white seam. No white stroke (the gap separates segments). Falls back to a plain donut for `n === 1`.

**Color system:**
- `node-color="<color>"` on container — base color for all slices (default `#2e6b8a`)
- `color="<color>"` on an `.item` — overrides that slice's color

**Sizing math:**
- `r = 210` when any slice has a gap, otherwise `240`. `sliceOffset = 20`.
- Each slice path is built around an origin offset `sliceOffset` along the slice's mid-angle when that slice has `.gap` (or all of them when the container has `.gap`).
- Label radius is `r * 0.6` (positioned at the slice mid-angle).
- Single-item pie: full circle path, label at center.

**Font scaling:**
- Same canvas `measureText` approach as circle-flow, but only scales *down* when the label would exceed `sliceWidth = 2·r·sin(π/n)·0.85` (with a 60px floor). Labels smaller than the slice keep their CSS size.

**Init guard:** Pie containers use the same `data-cf-init` flag as circle-flow, so they also only initialize once across `DOMContentLoaded` and Reveal `slidechanged`.

## Process layout

A linear flow layout, triggered by `.process` on the container. Items become nodes connected by arrows, horizontally by default. Implemented by `initProcess` in `diagrams.html`, with CSS for `.process` in `diagrams.css`.

```
::: process
::: item
Alice
:::
::: item
Bob
:::
::: item
Carol
:::
:::
```

**Class system:**
- `.process` on container — linear flow layout
- `.vertical` on container — flow top-to-bottom instead of left-to-right
- Node shapes: `.node-box` (default), `.node-circle`, `.node-none`
- Arrow types: `.arrow-chevron` (default, div with clip-path), `.arrow-thin`, `.arrow-double` (both SVG)
- `.chevron` on container — chevron style: each step *is* an interlocking arrow tile (no separate connectors). Overrides node shape and arrow type; honors `.vertical`, `.gap`, and the color system.
- `.arrow` on container — arrow style: a chevron sub-variant with deeper points and shorter tiles so each step reads as a distinct arrowhead. Implies chevron behavior.
- `.gap` on an item — enlarges the arrow slot *before* that item (gap weight 1.6 vs default 1)

**Color system:** Same as circle-flow — `node-color=` / `arrow-color=` on the container, `color=` per item.

**Sizing math:**
- Container default: 900×200 horizontal, 200×600 vertical (read from computed CSS, so users can override).
- Along the main axis: `n` nodes plus arrow slots between them. With per-item gap weights `w[i]` (1 by default, 1.6 if `.gap`), total gap weight is `Σ w[i]` for i=1..n-1.
- `nodeSize = mainAxis / (n + 0.5 · totalGapWeight)`, then `boxMain = nodeSize · 0.85` and `arrowSlot = (mainAxis - n·boxMain) / totalGapWeight`. This gives the baseline arrow slot ≈ 0.5× nodeSize.
- Box node cross-axis size = `boxMain · 0.6`; circle node is square at `min(boxMain, boxCross)`.
- Centers are placed at `boxMain/2`, `+ boxMain + arrowSlot·w[1]`, `+ boxMain + arrowSlot·w[2]`, …

**Arrow rendering:**
- `arrow-chevron`: div with the same chevron clip-path as circle-flow; sized to fit its arrow slot (capped by `boxCross·0.7`). In vertical mode the chevron is rotated 90°.
- `arrow-thin` / `arrow-double`: SVG `<line>` with arrow markers, trimmed by `boxMain/2 + 4` on each end so it starts at the node edge.

**Chevron style (`.chevron`):** Each step is rendered as a `.chevron-step` node with a `clip-path` polygon: middle steps point in the flow direction with an inward notch on the trailing edge; the first step has a flat tail, the last a flat head (`.vertical` points the chevrons downward). Tiles are sized `boxMain ≈ mainAxis/n` and interlock — the tip nests in the next notch — separated by a thin `gutter` (`boxCross·0.08`) so each seam reads against the page background. `notchPx = boxCross·0.4`; centers are spaced `boxMain − notchPx + gutter` apart. No connector divs/SVG are drawn (`initProcess` returns early). Labels are padded clear of the notch/tip.

**Arrow style (`.arrow`):** A chevron sub-variant (sets `chevron = true`) that renders each step as a true block arrow — a shorter rectangular shaft whose head flares into wings (the full cross-axis height) before tapering to the point — so each step reads as a distinct arrow rather than a block with a thin seam. The clip-path uses a `--wing` inset (`boxCross·0.24` per side) for the shaft, `--notch` for the head point depth, and a shallower `--tnotch` (`notch·(1 − 2·wingFrac)`) for the inward tail notch (flat on the first tile). The tail notch is deliberately shallower so its edges run **parallel** to the head's point-to-wing edges — the previous tile's point then nests with a uniform-width seam rather than a wedge-shaped gap. Unlike chevron, **every** tile (incl. the last) keeps its arrowhead; only the first tile's flat tail shifts the label centroid. Tiles are shorter/more landscape (`boxCross = min(crossAxis·0.62, (mainAxis/n)·0.55)`) with a deeper point (`notchPx = min(boxCross, (mainAxis/n)·0.32)`), versus chevron's taller tiles and shallow `notchPx = boxCross·0.4`. Interlock, gutter, `.vertical`, `.gap`, colors, and annotations are shared with chevron; labels are padded clear of both the tail notch and the head point.

**Init guard:** `.process` containers use the same `data-cf-init` flag and are picked up on both `DOMContentLoaded` and Reveal `slidechanged`.

## Pyramid layout

A stacked-triangle layout, triggered by `.pyramid` on the container. Items become horizontal bands of a triangle — the first item is the narrow apex, the last is the wide base. Implemented by `initPyramid` in `diagrams.html`, reusing the `.slice-label` CSS from the pie layout. Like the pie, it is SVG-based (the bands are non-rectangular).

```
::: pyramid
::: item
Vision
:::
::: item
Strategy
:::
:::
```

**Class system:**
- `.pyramid` on container — stacked-triangle layout
- `.inverted` on container — flips the triangle so the first item is the wide top (funnel)
- `.gap` on container — separates every band; `.gap` on an item separates just that band

**Color system:** Same as pie — `node-color=` on the container is the base color for all bands, `color=` on an item overrides one band. No white stroke between bands when in gap mode.

**Sizing math (500×500 SVG):**
- Triangle: apex `y=20`, base `y=480` (`H=460`), base half-width `230`, centered at `cx=250`.
- Band `i` of `n` spans `pTop=i/n` to `pBot=(i+1)/n` vertically. Half-width at fraction `p` is `halfAt(p) = (inverted ? 1-p : p) · 230`.
- Each band is a 4-point path `(cx∓topHalf, yTop)` → `(cx∓botHalf, yBot)`. The apex band's narrow end has half-width 0, so it renders as a triangle (degenerate trapezoid).
- `.gap` insets each band by `5px` top and bottom.

**Font scaling:** Per-label (not global), because band widths vary widely. Each label is scaled *down* with canvas `measureText` only if it exceeds `max(40, bandMidWidth · 0.85)`, where `bandMidWidth = 2 · halfAt((pTop+pBot)/2)`.

**Init guard:** `.pyramid` containers use the same `data-cf-init` flag and are picked up on both `DOMContentLoaded` and Reveal `slidechanged`.

## Matrix layout

A 2×2 matrix, triggered by `.matrix` on the container. The container expects exactly four `.item` divs, mapped to quadrants in reading order: **TL, TR, BL, BR**. Implemented by `initMatrix` in `diagrams.html`, reusing the `.slice-label` CSS for quadrant labels. SVG-based (one overlay holds the quadrant rects, divider/axis lines, and arrowheads); axis labels are positioned `div`s.

```
::: {.matrix x-axis="Market Share" y-axis="Growth" x-high="High" y-high="High"}
::: item
Question Marks
:::
::: item
Stars
:::
::: item
Dogs
:::
::: item
Cash Cows
:::
:::
```

**Class system:**
- `.matrix` on container — 2×2 quadrant layout
- `.arrows` — draws axis lines along the bottom and left edges with arrowheads pointing toward the "high" direction (right on x, up on y); end labels move outward to clear the axes (`offEnd` 40 vs 16)
- `.outline` — transparent cells with border + divider lines, dark labels, no fills
- `.gap` — separates the four cells (inset `6px` each side), removes the center divider lines

**Attributes (all optional, read via `dataset.*`; write WITHOUT the `data-` prefix in source):**
- End labels: `x-low` / `x-high` / `y-low` / `y-high` (`dataset.xLow`, etc.)
- Axis titles: `x-axis` / `y-axis` (`dataset.xAxis`, `dataset.yAxis`). `x-axis` is centered below the square; `y-axis` is centered on the left, rotated −90°.

**Color system:** Filled by default — `node-color=` on the container is the base fill for all four quadrants, `color=` on an item overrides one quadrant (same as pie/pyramid). Divider/axis lines use `arrow-color=` (default `#333`). In `.outline` mode there are no fills.

**Sizing math (500×500 SVG):**
- Square bounds `x0=70, y0=60, x1=430, y1=420`, center `cx=250, cy=240`. The gutter leaves room for axis labels/titles.
- Quadrants are the four equal rects around the center. `.gap` insets each by `6px`.
- Center cross is two `<line>`s through `cx`/`cy`, skipped in `.gap` mode. `.outline` draws per-cell border rects plus the center cross.
- `.arrows` draws the y-axis (bottom→top) at `x0-22` and the x-axis (left→right) at `y1+22`, each with an `addArrowMarker` arrowhead.

**Font scaling:** Global down-scale (cells are equal-sized), like pie — labels shrink only if the longest exceeds `cellW · 0.85` (60px floor).

**Init guard:** `.matrix` containers use the same `data-cf-init` flag and are picked up on both `DOMContentLoaded` and Reveal `slidechanged`.

## Hierarchy layout

A top-down org chart / tree, triggered by `.hierarchy` on the container. This is the **only layout that reads DOM structure rather than a flat `.item` list** — `.item` divs are nested to express parent/child relationships. Implemented by `initHierarchy` in `diagrams.html`, with CSS for `.hierarchy .node` in `diagrams.css`. Connectors are SVG elbow paths behind the nodes; nodes are absolutely-positioned `div`s.

```
::::: hierarchy
:::: item
CEO
::: item
CTO
:::
::: item
CFO
:::
::::
:::::
```

**Tree parsing:** Two helpers drive this. `directItemChildren(el)` returns only direct-child `.item` divs (`querySelectorAll('.item')` would flatten the tree). `ownLabel(el)` clones the node, strips nested `.item` children, and reads the remaining text — so a parent's label excludes its descendants' text. The container's direct `.item` children are the roots (a forest is allowed; roots are laid out side by side).

**Class system:**
- `.hierarchy` on container — org-chart layout
- `.horizontal` on container — grow left-to-right instead of top-down
- `.outline` on container — transparent nodes, colored border, dark text
- Node shapes: `.node-box` (default), `.node-circle`, `.node-none`

**Color system:** `node-color=` on the container is the base color for all nodes, `color=` on an item overrides one node. Connector lines use `arrow-color=` (default `#333` like matrix).

**Layout algorithm (pre-scale, then scaled to fit):**
- "main axis" = the growth direction (vertical by default, horizontal with `.horizontal`); "cross axis" is perpendicular. `breadth` is the node's extent along the cross axis.
- Baseline box: `130×54` (`90×90` for circles). `gap=24` between sibling subtrees, `levelGap=56` between depth levels.
- **Width pass** (post-order): leaf `extent = breadth`; parent `extent = max(breadth, Σ children extent + gap·(n−1))`.
- **Position pass** (pre-order): each parent is centered over the span of its children; leaves are placed left-to-right within their allotted extent. `node.c` (cross-axis center) = midpoint of first/last child centers; `node.m` (main-axis center) = `depth · level + box/2`.
- `(c, m)` is mapped to `(x, y)` depending on orientation, then the whole tree's bounding box is computed and scaled by `min(900/rawW, 520/rawH, 1)` to fit the viewport. Container width/height are set to the scaled bbox.

**Connectors:** One SVG elbow `path` per non-root node, from the parent's bottom-center (or right-center when horizontal) to the child's top-center (or left-center), routed through the midpoint between levels: `M … V mid H … V …` (vertical) or `M … H mid V … H …` (horizontal). Inserted before the node divs so they sit behind.

**Font scaling:** Per-node canvas `measureText` down-scale to fit `boxW·scale − 16` (boxes are uniform width), like pyramid but with a single shared max width.

**Init guard:** `.hierarchy` containers use the same `data-cf-init` flag and are picked up on both `DOMContentLoaded` and Reveal `slidechanged`.

## Venn layout

Overlapping circles for **2 or 3 sets**, triggered by `.venn` on the container. Each `.item` is one set; the layout returns early for fewer than 2 or more than 3 items. Implemented by `initVenn` in `diagrams.html`, with CSS for `.venn .set-label` / `.venn .overlap-label` in `diagrams.css`. SVG-based: each set is an SVG `<circle>` with `fill-opacity: 0.45` and `mix-blend-mode: multiply`, so overlaps darken automatically without computing intersection geometry.

```
::: {.venn ab="Shared"}
::: item
Frontend
:::
::: item
Backend
:::
:::
```

**Class system:**
- `.venn` on container — 2-/3-set Venn layout

**Attributes (overlap labels, all optional, read via `dataset.*`; write WITHOUT the `data-` prefix in source):**
- 2-set: `ab` — intersection label.
- 3-set: `ab`, `bc`, `ac` — pairwise intersections; `abc` — triple overlap. `a`/`b`/`c` are the 1st/2nd/3rd items in order.
- `overlap-color` (`dataset.overlapColor`) — text color applied to all intersection labels (default `#222222` from CSS).

**Color system:** Each set defaults to a distinct palette color (`['#2e6b8a', '#c0584f', '#5a9367']`). `color=` on an item overrides that circle. `node-color=` on the container sets one shared base color for all circles (overrides the palette). No `arrow-color` (no lines).

**Sizing math (500×500 container, SVG):**
- 2-set: two circles `r=150` at `(175,250)` and `(325,250)` (center distance 150 → symmetric lens). Set labels at `(120,250)` / `(380,250)`; overlap `ab` at `(250,250)`.
- 3-set: three circles `r=140` in a trefoil at `(250,155)`, `(320,275)`, `(180,275)`. Set labels at `(250,95)` / `(380,330)` / `(120,330)`; overlaps `ab`=`(320,200)`, `ac`=`(180,200)`, `bc`=`(250,330)`, `abc`=`(250,245)`.

**Font scaling:** Global down-scale of set labels (like pie/matrix) — shrinks only if the longest exceeds a fixed lobe width (`150` for 2-set, `130` for 3-set). Overlap labels are not scaled.

**Init guard:** `.venn` containers use the same `data-cf-init` flag and are picked up on both `DOMContentLoaded` and Reveal `slidechanged`.

## Stacked Venn layout

**Nested concentric circles** sharing a common bottom edge, triggered by `.stacked-venn` on the container (modeled on PowerPoint's "Stacked Venn" SmartArt). Unlike `.venn` (which shows set intersections), this expresses a **containment / subset relationship**: the first item is the largest outer circle and each subsequent item nests inside the previous one. Takes **any number of circles** (≥2). Each `.item` is one circle whose label sits in its exclusive band. Implemented by `initStackedVenn` in `diagrams.html`, with its own white `.stacked-venn .set-label` CSS. SVG-based with **opaque fills painted largest-first** so inner (smaller) circles sit on top — no blend mode, since the relationship is containment, not intersection.

```
::: stacked-venn
::: item
Total Population
:::
::: item
Vitamin D Deficiency
:::
::: item
Deficiency
:::
:::
```

**Class system:**
- `.stacked-venn` on container — nested concentric circles

**Attributes (orientation, optional, read via `dataset.*`; write WITHOUT the `data-` prefix in source):**
- `direction` — which edge the circles nest toward: `down` (default), `up`, `left`, `right`.
- `angle` — extra clockwise rotation in degrees, added on top of `direction`. The diagram rotates but **labels stay upright** (they are absolutely-positioned divs, never rotated).

**Color system:** Each circle defaults to a distinct palette color (`['#c0584f', '#5a9367', '#7a5a9b', '#2e6b8a', '#b8893a']`, cycled for n>5). `color=` on an item overrides that circle. `node-color=` on the container sets one shared base color for all circles. No `arrow-color` (no lines), no overlap-label attributes.

**Sizing math (500×500 SVG):**
- Outer radius `R = 250 − margin` (`margin = 10`), figure centered at `C0 = (250, 250)`. The outer circle always fills the box regardless of orientation, so no fitting/scaling pass is needed.
- The shared tangent point sits in direction `u = (cos θ, sin θ)`, where `θ = baseDeg(direction) + angle` (`down→90°`, `up→−90°`, `left→180°`, `right→0°`, in y-down screen coords).
- Circle `i` (0 = outermost) has radius `r_i = R·(n−i)/n` and center `C0 + (R − r_i)·u`, so all circles are internally tangent at `P = C0 + R·u`.

**Labels:** Placed along the `−u` axis through `C0`, at distance `R − r_i − r_{i+1}` from `C0` — the middle of circle `i`'s exclusive crescent (the band on the far side from `P`, between its far rim and the next inner circle's far rim). The innermost label is at `R − r_last` (the middle of its body). Labels are never rotated.

**Font scaling:** Per-label down-scale (bands vary in width) to fit `0.8 ×` the circle's chord width at the label's position — `dist` is the label's distance from that circle's center — with a `40px` floor, via canvas `measureText`.

**Init guard:** `.stacked-venn` containers use the same `data-cf-init` flag and are picked up on both `DOMContentLoaded` and Reveal `slidechanged`.

## Annotations

External callouts attached to a shape via a nested `.annotation` div, supported by every layout except matrix and hierarchy. The shared helper `placeAnnotations` (radial/segmented layouts) stacks the callouts in side columns and draws a leader line from each shape's outer edge to its callout; `.process` draws its own stub line (vertical leaders beside a column, or short up/down stubs above/below a row).

**Styling attributes (container-level, read via `dataset.*`; write WITHOUT the `data-` prefix):**
- `ann-line` — leader-line style: `solid` (default), `dashed`, `dotted`, or `none` (no line drawn).
- `ann-line-color` — line color; `auto` (default) follows the shape color, otherwise any CSS color (e.g. a neutral `#bbb`).
- `ann-title-color` — tint of the callout's bold/heading run; `auto` (default) follows the shape color, `none` inherits the body text color (~`#444`), otherwise any CSS color.

**Implementation decisions:**
- **Centralized line creation.** `annOpts(container)` reads the three attributes once per init; `makeLeaderLine(opts, shapeColor, x1, y1, x2, y2)` returns a styled `<line>` (or `null` when `ann-line="none"`), used by both `placeAnnotations` and the inline `.process` line site so the two paths can't drift. Dotted uses `stroke-linecap: round` + a `1 5` dash array; dashed uses `6 5`.
- **`auto` sentinel preserves backward compatibility** — the pre-existing behavior (solid, shape-colored line; shape-colored title) is exactly the default.
- **Title tint stays CSS-driven.** `.annotation strong/b/headings { color: var(--ann-color) }` is unchanged; JS only chooses the value fed to `--ann-color` via `annTitleColor(opts, shapeColor)` (`none` → `inherit`).
- **Line style is an attribute, not a class**, because it is an enumerated value, unlike the boolean `.gap` flags.
- Styling is container-level only; per-item override is not implemented (the helper already takes a per-anchor color, so it would be a small addition).
