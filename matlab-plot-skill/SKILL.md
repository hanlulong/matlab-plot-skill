---
name: matlab-plot-skill
description: "Use this skill when MATLAB figures look messy: cramped subplots, unreadable titles, awkward legends, bad page fit, or broken PDF output for LaTeX or Overleaf. It turns rough MATLAB plots into publication-quality figures by exporting the figure, reading the rendered figure, and iterating on the layout until it looks clean."
---

# MATLAB Plot Skill

## Overview

Use this skill to fix messy MATLAB figures and turn rough plots into publication-quality output. The workflow is: read the plotting code and destination document, refactor the figure, export a vector PDF plus a PNG preview, **read the rendered PNG yourself**, critique it, and iterate until the result is clearly professional.

The non-negotiable idea: do not stop after writing plotting code. Code that looks correct is not the same as a figure that looks correct — you must generate, export, look, and iterate.

## When To Use It

- MATLAB `.m` files that create or export figures.
- Figures that look cramped, blurry, inconsistent, or amateurish.
- Multi-panel paper figures where spacing, legends, titles, and page fit matter.
- Overleaf or LaTeX workflows that need vector PDF output.
- Requests like `publication-quality`, `journal-ready`, `clean up this figure`, `make this plot readable`, or anything that effectively means "this MATLAB figure looks messy."

## Non-Negotiable Review Loop

Do not stop after writing plotting code.

1. **Read** the plotting script and the destination file (`.tex`, `.md`, slide deck) that will include the figure. Decide the figure's final printed width first: look in the `.tex` for `\columnwidth` (single column, ~3.3 in) vs `\textwidth` (~6.5 in), and size fonts for that width.
2. **Generate** the figure by running MATLAB headlessly, and lint any script you write:
   ```bash
   matlab -batch "checkcode('make_figure.m'); run('make_figure.m')"
   ```
   `-batch` runs without a desktop, exits when finished, and returns a nonzero exit code on error; `checkcode` surfaces syntax/usage warnings to fix before you trust the run.
3. **Export** a vector PDF for the paper and a raster PNG preview:
   ```matlab
   exportgraphics(fig, 'figure.pdf', 'ContentType', 'vector');   % deliverable
   exportgraphics(fig, 'figure.png', 'Resolution', 220);         % what you read
   ```
   (Or pass `PreviewPath` to `scripts/export_publication_figure.m` to get both at once.)
4. **Read the PNG** with your image-reading tool. You cannot visually inspect a vector PDF directly, so the PNG preview is the read target — the PDF is the deliverable. If only a PDF exists, rasterize page 1 first (`pdftoppm -png -r 200 -singlefile figure.pdf out` or `magick -density 200 figure.pdf out.png`, both producing `out.png`).
5. If you can compile the document, render the embedded page and read it too. This step is conditional — never skip step 4 because step 5 is impossible.
6. **Critique** the rendered PNG against [`references/render_review_checklist.md`](./references/render_review_checklist.md): aspect ratio, whitespace, title readability, legend placement, font sizes, clipping, marker visibility, line weights, panel balance, and page fit.
7. **Iterate** on the MATLAB code and repeat the export until the figure is clearly professional.

**If MATLAB is not available**, do not claim the figure was rendered or reviewed. Deliver the refactored `.m` code, state plainly that it was not executed or visually verified, and give the user the exact `matlab -batch` command to run plus what to check. The same honesty applies whenever you cannot read the rendered figure for any reason.

## Worked Recipe

The full loop in one place — build, export both files, then read the PNG:

```matlab
addpath('<skill>/scripts');   % e.g. ~/.claude/skills/matlab-plot-skill/scripts

fig = figure;
tl = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; plot(x, y1); title('Panel A');
nexttile; plot(x, y2); title('Panel B');
% ... remaining panels, one shared legend ...

export_publication_figure(fig, 'out/figure.pdf', ...
    WidthInches=6.5, PreviewPath='out/figure.png');
```

Then **read `out/figure.png`** and iterate. (If you would rather not depend on the helper, the two `exportgraphics` lines in step 3 do the same export inline.)

## Common Defects → Fix

Look for these in the rendered PNG; read [`references/matlab_figure_guidelines.md`](./references/matlab_figure_guidelines.md) for the full rules and rationale before styling.

- Cramped panels → increase canvas height before shrinking fonts.
- Tiny text after `\columnwidth` scaling → export at the final width so LaTeX needs no scaling.
- Legend stealing plot area → one shared legend docked outside the tiles (`lgd.Layout.Tile = 'south'`).
- Thin lines / small markers after scaling → raise line width and marker size.
- Crowded or rainbow colors → one concept per color, colorblind-safe palette; `parula`/`viridis` (not `jet`) for continuous data.
- Crowded ticks or a corner `1e4` multiplier → sparse explicit ticks; `ax.YAxis.Exponent = 0`.
- Clipped titles or labels → loosen `TileSpacing`/`Padding`.

## Decisions

- Refactor an existing `.m` in place: preserve the data and computation, change only styling and layout.
- Move `subplot` to `tiledlayout` unless rewriting would risk the user's intent on code they want minimally touched.
- Default to vector PDF; rasterize (`exportgraphics(ax, ..., 'ContentType', 'image')` at 300–600 DPI) only when one layer has many thousands of primitives and the vector PDF becomes huge or slow to compile.

## Helper

[`scripts/export_publication_figure.m`](./scripts/export_publication_figure.m) applies explicit sizing, readable defaults, and the vector-PDF + PNG-preview export. Copy it into the project, or add its folder to the MATLAB path (`addpath('<skill>/scripts')`) before calling it, as in the recipe above.

## Report Back

- State what changed in the MATLAB code.
- Cite the exact PNG path you read and at least one concrete thing you observed and acted on (e.g. "legend overlapped Panel B, moved it outside"). If you could not render or read it, say so and state what remains unverified.
- Mention any remaining limitations, warnings, or assumptions.

## Resources

- [`scripts/export_publication_figure.m`](./scripts/export_publication_figure.m): reusable export helper for publication-style figures.
- [`references/matlab_figure_guidelines.md`](./references/matlab_figure_guidelines.md): structural, color, sizing, and layout conventions — read before styling.
- [`references/render_review_checklist.md`](./references/render_review_checklist.md): the post-export visual checklist — work through it before declaring the figure done.
