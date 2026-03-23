---
name: matlab-plot-skill
description: "Use this skill when MATLAB figures are messy: cramped subplots, unreadable titles, awkward legends, bad page fit, or broken PDF output for LaTeX or Overleaf. It is for turning rough MATLAB plots into publication-quality figures by exporting the figure, reading the rendered figure, and then iterate on the layout until it looks clean."
---

# MATLAB Plot Skill

## Overview

Use this skill to fix messy MATLAB figures and turn rough plots into publication-quality output. The default workflow is: read the plotting code and destination document, generate or refactor the MATLAB figure, export a vector PDF, read the rendered figure yourself, critique it, and iterate until the result is clearly professional.

## When To Use It

- MATLAB `.m` files that create or export figures.
- Existing figures that look cramped, blurry, inconsistent, or amateurish.
- Multi-panel paper figures where spacing, legends, titles, and page fit matter.
- Overleaf or LaTeX workflows that need vector PDF output.
- Requests using phrases like `publication-quality`, `professional`, `journal-ready`, `clean up this figure`, or `make this plot readable`.
- Requests that effectively mean `this MATLAB figure looks messy`.

## Non-Negotiable Review Loop

Do not stop after writing plotting code.

1. Read the current plotting script and the destination file that will include the figure.
2. Generate the figure in MATLAB.
3. Export the figure, using vector PDF by default via `exportgraphics(..., 'ContentType', 'vector')`.
4. Read the generated figure yourself.
5. If the figure is embedded in a paper or slide deck, compile or render the destination page and read that page too.
6. Critique the actual rendered output: aspect ratio, whitespace, title readability, legend placement, font sizes, clipping, marker visibility, line weights, panel balance, and page fit.
7. Iterate the MATLAB code and repeat the export until the figure looks professional.

If you cannot read the rendered figure, say so explicitly and state what remains unverified.

## Workflow

### 1. Build Context

- Read the plotting script, data source, and destination `.tex`, `.md`, or slide file.
- Identify whether the figure is standalone or embedded on a page.
- Determine the intended physical size on the final page before tuning fonts and spacing.

### 2. Choose the Figure Structure

- Prefer `tiledlayout` over `subplot` for multi-panel figures.
- Use a shared legend when repeated legends waste space.
- Keep subplot titles short and readable.
- Remove redundant labels, but keep scale information.
- Keep color semantics fixed across panels. Use markers or line styles for secondary distinctions before adding more colors.

### 3. Apply MATLAB Plotting Standards

- Start from [`scripts/export_publication_figure.m`](./scripts/export_publication_figure.m) when the figure needs a clean export path.
- Use the helper's optional PNG preview export when a quick visual review image will speed up iteration.
- Set the figure size explicitly in inches rather than relying on defaults.
- Use vector PDF for LaTeX unless the destination explicitly needs a raster format.
- Keep line widths, marker sizes, and fonts readable after the figure is scaled down on the page.
- Use `TileSpacing` and `Padding` intentionally. `compact` is a starting point, not a rule.

### 4. Export and Read the Result

- Export the figure.
- Open the PDF or rendered paper page.
- Read the actual output rather than assuming the code is correct.
- Make concrete visual judgments about spacing, crowding, hierarchy, and readability.

### 5. Iterate

- If the figure feels compressed, increase physical height before shrinking fonts.
- If panel titles are hard to read, shorten them and increase title font size.
- If the legend steals too much room, move to a shared legend or an external location.
- If axes repeat the same information, simplify selectively.
- If markers or line differences disappear after scaling, strengthen them.

### 6. Report Back

- State what changed in the MATLAB code.
- State that you read the generated figure and, when applicable, the compiled page.
- Mention any remaining limitations, warnings, or assumptions.

## Figure Standards

- Prefer vector PDF output for papers.
- Use explicit physical dimensions such as `Units='inches'` and `Position=[x y width height]`.
- Use one consistent palette across the full figure.
- Use marker shape or line style to distinguish closely related series.
- Keep subplot titles short and descriptive.
- Avoid oversized legends, notes, and annotations inside the data area.
- Make sure the figure still reads after LaTeX scaling.
- Fix clipping, crowded tick labels, and inconsistent axis ranges before declaring the work done.

## Common Fixes

- Too short or compressed: increase canvas height or width and loosen tile spacing.
- Titles too dense: shorten the wording and raise the title font size.
- Legend dominates the panel: switch to one shared legend or place it outside the tiles.
- Too many colors: map colors to concepts and use symbols or line styles for variants.
- Weak panel hierarchy: add panel headers, reduce repeated text, and align axes consistently.
- Looks fine in MATLAB but bad in the paper: inspect the compiled page and retune for page scale.

## Resources

- [`scripts/export_publication_figure.m`](./scripts/export_publication_figure.m): reusable export helper for publication-style MATLAB figures.
- [`references/render_review_checklist.md`](./references/render_review_checklist.md): visual checklist for the render-review-iterate loop.
- [`references/matlab_figure_guidelines.md`](./references/matlab_figure_guidelines.md): coding and design conventions for professional MATLAB figures.
