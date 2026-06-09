# quarto-diagrams

A Quarto extension that turns plain div syntax into clean, presentation-ready
diagrams. Built for Reveal.js slides and HTML documents — no external image
tools, no hand-drawn SVG. You write nested `::: item` divs, the extension lays
them out and draws the connectors.

📖 [Documentation & live examples](https://emilhvitfeldt.github.io/quarto-diagrams/)

## Installation

```bash
quarto add EmilHvitfeldt/quarto-diagrams
```

Then activate it in your document's YAML:

```yaml
filters:
  - diagrams
```

## Usage

Each layout is a div with a layout class, containing a flat list of `::: item`
divs (only `.hierarchy` uses nesting):

```markdown
::: circle-flow
::: item
Plan
:::
::: item
Build
:::
::: item
Ship
:::
:::
```

## Layouts

| Class | Description |
|-------|-------------|
| `.circle-flow` | Nodes arranged on a ring, connected by arrows |
| `.pie` | Pie chart (`.donut` subtype available) |
| `.process` | Linear left-to-right (or `.vertical`) flow |
| `.pyramid` | Stacked triangle bands (`.inverted` for a funnel shape) |
| `.matrix` | 2×2 quadrant matrix with optional axes |
| `.hierarchy` | Top-down org chart / tree (reads nested items) |
| `.venn` | 2- or 3-set overlapping circles |
| `.stacked-venn` | Nested concentric circles (containment) |
| `.funnel` | Narrowing stages, optionally sized by `value=` |
| `.cycle` | Ring of arc-shaped arrow segments |

## Customization

- **Colors** — `node-color=` and `arrow-color=` on the container, `color=` on an
  individual item. Write attributes *without* a `data-` prefix.
- **Node shapes** — `.node-circle`, `.node-box`, `.node-none`.
- **Arrow styles** — `.arrow-chevron`, `.arrow-curved`, `.arrow-thin`,
  `.arrow-ring`, `.arrow-arc`, `.arrow-double`.
- **Annotations** — nest an `.annotation` div in an item to attach a side
  callout with a leader line.

See the [documentation](https://emilhvitfeldt.github.io/quarto-diagrams/) for the
full set of options, attributes, and examples for each layout.

## Note

Items are **plain text only** — rich markup inside an `.item` (bold, links, math,
images) is flattened to plain text.
