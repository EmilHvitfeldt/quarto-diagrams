# quarto-chevrons

See `DESIGN.md` for full design documentation, class system, color system, and decision log.

## Key files

- `_extensions/circle-flow/` — the extension (CSS, JS, Lua filter)
- `index.qmd` — demo slides; activate extension with `filters: [circle-flow]`

## Important rules

- Do NOT use SVG stroke + `marker-end` for curved arrows — use filled paths instead
- Do NOT use `contributes.format` in `_extension.yml` to inject CSS/JS — use the Lua filter
- Do NOT use plain hyphenated HTML attributes for colors — use `data-*` prefix
