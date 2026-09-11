# Changelog

## 0.5.0

- Add `.outside-labels` for `.venn`: places each set label just outside its
  circle's rim (plain text, no leader line) instead of inside its exclusive
  lobe.
- Fix `.venn` overlap divs (`.overlap.ab`/`.ac`/`.bc`/`.abc`) dropping any
  markup (e.g. images) in their non-`.annotation` content: the label is now
  built with the same `labelHTML()` helper items use, instead of
  `textContent`, so inline HTML renders inside the diagram instead of being
  silently stripped.
- Add nested `.icon` div support for `.venn` items: content in `.icon` stays
  pinned inside the circle's default position even when `.outside-labels`
  pushes the rest of the label outside the rim.
- Add independent outline control for `.venn` circles: `outline-color=` /
  `outline-width=` (per `.item`, or as a `.venn` container default) draw a
  stroke separate from the existing `color=` fill. No outline is drawn unless
  a color is given. `fill-opacity=` is also now overridable (per-item or on
  the container), defaulting to the previous `0.45`.
- Support Reveal.js fragments on `.venn` icons: add `.fragment` (plus any
  fade-*/highlight-*/etc. modifier and an explicit `data-fragment-index`) to
  an `.icon` or `.overlap` div and it carries over to the rendered element, so
  icons can be revealed on click — give several the same
  `data-fragment-index` to have them appear together. Diagrams now call
  `Reveal.sync()` after building so dynamically-added fragments get indexed.
  An inline `style` on the same div (e.g. `transition-delay: 0.5s;`) also
  carries over, so same-index fragments can be staggered visually while still
  triggering on one click.

## 0.4.0

- Add annotation support for `.venn` overlap regions: a sibling `.overlap` div
  (classed `.ab`/`.ac`/`.bc`/`.abc`) can carry a nested `.annotation` callout
  for an intersection, the same way `.item` divs already do for sets.

## 0.3.0

- Add external `.annotation` callouts: nest an `.annotation` div in any item to
  attach a side callout with a leader line. Supported on `.pie`, `.circle-flow`,
  `.cycle`, `.venn`, `.stacked-venn`, `.funnel`, `.pyramid`, and `.process`.
  Annotations support additional customization options.
- Add `.donut` subtype for `.pie` (`hole=`, `center=`).
- Add `.arrow` subtype for `.process`: a chevron variant with deeper points and
  shorter tiles so each step reads as a distinct arrowhead.
- Add `.arrow` subtype for `.pie` and an arrow `.progress` subtype.
- Support Font Awesome icons in item content.

## 0.2.0

- Add `.funnel` and `.cycle` layouts.
- Add `.venn` and `.stacked-venn` layouts.
- Add `.hierarchy`, `.matrix`, `.pyramid`, and `.process` layouts.
- Add `direction=` and `angle=` attributes.
- Add Quarto Wizard support (schema + snippets).
- Rename extension to `diagrams`.

## 0.1.0

- Initial release: `.circle-flow` and `.pie` layouts.
