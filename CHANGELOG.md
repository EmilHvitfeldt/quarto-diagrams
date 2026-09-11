# Changelog

## Unreleased

- Add `.outside-labels` for `.venn`: places each set label just outside its
  circle's rim (plain text, no leader line) instead of inside its exclusive
  lobe.

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
