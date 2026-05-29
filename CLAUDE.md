# quarto-diagrams

See `DESIGN.md` for full design documentation, class system, color system, and decision log.

## Key files

- `_extensions/diagrams/` — the extension (CSS, JS, Lua filter). Provides two layouts: `.circle-flow` (nodes-on-a-ring with arrows) and `.pie` (pie chart). Both initialize from the same JS file (`initCircleFlow` / `initPie`).
- `index.qmd` — demo slides; activate extension with `filters: [diagrams]`
- `docs/` — documentation website (`quarto render docs/` to build, output in `docs/_site/`)
- `docs/_extensions/diagrams/` — **copy** of `_extensions/diagrams/`; Quarto does not follow symlinks for extension lookup, so this must be kept in sync manually when the extension changes

## Keeping docs in sync

When adding or changing extension features:
1. Copy changed files to `docs/_extensions/diagrams/`
2. Update `docs/` source files to document the new feature
3. Run `quarto render docs/` to rebuild the site

## Testing with Playwright

Use `test.qmd` as a minimal one-slide test file — edit it, render, then screenshot:

```bash
quarto render test.qmd
```

A local HTTP server must be running (file:// protocol is blocked by Playwright MCP):

```bash
python3 -m http.server 8765
```

Then navigate and screenshot via Playwright MCP:
- `mcp__playwright__browser_navigate` → `http://localhost:8765/test.html`
- `mcp__playwright__browser_take_screenshot`
- `mcp__playwright__browser_press_key` with `ArrowRight` / `ArrowDown` to move between slides

Screenshots and snapshots are saved to `.playwright-mcp/` (gitignored). The folder is automatically cleared before each `browser_navigate` call via a PreToolUse hook.

## Important rules

- Do NOT use SVG stroke + `marker-end` for curved arrows — use filled paths instead
- Do NOT use `contributes.format` in `_extension.yml` to inject CSS/JS — use the Lua filter
- In Quarto source, write attributes WITHOUT a `data-` prefix — `node-color=`, `arrow-color=`, `color=`. Pandoc auto-prefixes unrecognized attrs with `data-` in the emitted HTML (e.g. `node-color` → `data-node-color`), so the JS reads container attrs via `dataset.nodeColor` / `dataset.arrowColor`. The legacy HTML attribute `color` is the exception — it passes through unprefixed, so the JS checks `getAttribute('color')` first then `dataset.color`.
- Boolean flags use classes, not attributes — e.g. `.gap` on an item, not `data-gap="true"`
- When clearing the Quarto freeze cache for a page, delete `docs/_freeze/<page-name>/` then re-render
