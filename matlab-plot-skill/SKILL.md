---
name: matlab-plot-skill
description: "Creates, cleans up, and exports publication-quality MATLAB figures for papers, LaTeX or Overleaf documents, and Beamer slides. Use when writing or fixing MATLAB plotting code (plot, tiledlayout, subplot, exportgraphics, print, saveas) or when a MATLAB figure looks messy: cramped panels, unreadable titles or fonts, awkward legends, bad fit at the column or text width, or broken PDF output. Runs MATLAB headlessly, exports a vector PDF plus a PNG preview, reads the rendered figure, and iterates until the layout is clean. Not for matplotlib, R, Stata, or Excel charts."
license: MIT
metadata:
  version: "0.2.0"
---

# MATLAB Plot Skill

## Overview

Use this skill to build new MATLAB figures or fix messy ones, and turn rough plots into publication-quality output. The workflow is: read the plotting code and destination document, refactor the figure, export a vector PDF plus a PNG preview, **read the rendered PNG yourself**, critique it, and iterate until the result is clearly professional.

The non-negotiable idea: do not stop after writing plotting code. Code that looks correct is not the same as a figure that looks correct — you must generate, export, look, and iterate.

## When To Use It

- MATLAB `.m` files that create or export figures (new figures as well as existing ones).
- Figures that look cramped, blurry, inconsistent, or amateurish.
- Multi-panel paper figures where spacing, legends, titles, and page fit matter.
- Overleaf or LaTeX workflows that need vector PDF output, including figures for Beamer slides.
- Requests like `publication-quality`, `journal-ready`, `clean up this figure`, `make this plot readable`, or anything that effectively means "this MATLAB figure looks messy."

Requires MATLAB R2021a+ (run headlessly with `matlab -batch`). Optional: `pdftoppm` (Poppler) or ImageMagick to rasterize a PDF for reading.

## Non-Negotiable Review Loop

Do not stop after writing plotting code.

1. **Read** the plotting script and the destination file (`.tex`, `.md`, slide deck) that will include the figure. Decide the figure's final printed width first. Find the width the document includes it at (`\linewidth`, `\columnwidth`, `\textwidth`, or a fraction such as `0.8\textwidth`). In a one-column document `\columnwidth` equals `\textwidth` (345 pt = 4.77 in for the default 10 pt `article`; 6.5 in with 1-in margins on letter paper); only two-column classes have a narrow column of about 3.2–3.5 in. When unsure, measure it: put `\typeout{\the\linewidth}` inside the figure environment, compile, and divide the logged points by 72.27 (see [Sizing And Page Fit](./references/matlab_figure_guidelines.md#sizing-and-page-fit)). Export at that width and size fonts for it.
2. **Generate** the figure by running MATLAB headlessly from the folder the script expects (usually the project root), and lint any script you write:
   ```bash
   matlab -batch "addpath('Plots'); checkcode('Plots/make_figure.m'); make_figure"
   ```
   Calling the script by name keeps MATLAB in the current folder, so paths such as `load('data/irf.mat')` resolve from the project root. `run('Plots/make_figure.m')` changes into `Plots/` while the script runs and breaks those paths; use it only for scripts that build their paths from `mfilename('fullpath')`. `-batch` runs without a desktop, exits when finished, and returns a nonzero exit code on error; `checkcode` surfaces syntax/usage warnings to fix before you trust the run.
   - **`matlab: command not found`** often means MATLAB is installed but not on `PATH`, which is common on macOS (MathWorks documents starting it from `matlabroot/bin`). Before concluding MATLAB is missing, look for `/Applications/MATLAB_R20*.app/bin/matlab` (macOS), `C:\Program Files\MATLAB\R20*\bin\matlab.exe` (Windows), or `/usr/local/MATLAB/R20*/bin/matlab` (Linux), and call it by its full path.
   - **In Codex**, MATLAB cannot start inside the sandbox on macOS. On Apple Silicon it exits with `Incompatible processor. This Qt build requires the following features: neon` (exit code 137). That message means the sandbox blocked MATLAB, not that MATLAB is broken or missing. Request escalated permissions to run the `matlab` command outside the sandbox, and let the user approve it; do not retry inside the sandbox.
3. **Export** a vector PDF for the paper and a raster PNG preview:
   ```matlab
   exportgraphics(fig, 'figure.pdf', 'ContentType', 'vector');   % deliverable
   exportgraphics(fig, 'figure.png', 'Resolution', 220);         % what you read
   ```
   On R2025a+ add `'Width', w, 'Height', h, 'Units', 'inches'` to both calls. Without them the export is cropped to its content, about 5–15% smaller than the figure, and LaTeX scales the text up to fill the width. (Or pass `PreviewPath` to `scripts/export_publication_figure.m`, which exports both files at the exact size.)
4. **Read the PNG** with your image-reading tool. You cannot visually inspect a vector PDF directly, so the PNG preview is the read target — the PDF is the deliverable. If only a PDF exists, rasterize page 1 first (`pdftoppm -png -r 200 -singlefile figure.pdf out` or `magick -density 200 figure.pdf out.png`, both producing `out.png`).
5. If you can compile the document, render the embedded page and read it too. This step is conditional — never skip step 4 because step 5 is impossible.
6. **Critique** the rendered PNG against [`references/render_review_checklist.md`](./references/render_review_checklist.md): aspect ratio, whitespace, title readability, legend placement, font sizes, clipping, marker visibility, line weights, panel balance, and page fit.
7. **Iterate** on the MATLAB code and repeat the export until the figure is clearly professional.

**If MATLAB is not available** (not on `PATH`, not in the usual install folders, or not allowed to run outside the sandbox), do not claim the figure was rendered or reviewed. Deliver the refactored `.m` code, state plainly that it was not executed or visually verified, and give the user the exact `matlab -batch` command to run plus what to check. The same honesty applies whenever you cannot read the rendered figure for any reason.

## Worked Recipe

The full loop in one place — build, export both files, then read the PNG. `${CLAUDE_SKILL_DIR}` is the folder containing this SKILL.md; Claude Code fills it in. If it still appears literally (as in Codex), use the folder this file was loaded from: typically `~/.agents/skills/matlab-plot-skill`, or a folder under `~/.codex/plugins/cache/` for a plugin install.

```matlab
addpath(fullfile('${CLAUDE_SKILL_DIR}', 'scripts'));

fig = figure;
tl = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; plot(x, y1); title('Panel A');
nexttile; plot(x, y2); title('Panel B');
% ... remaining panels, one shared legend ...

export_publication_figure(fig, 'out/figure.pdf', ...
    WidthInches=6.5, HeightInches=4.5, PreviewPath='out/figure.png');
```

Then **read `out/figure.png`** and iterate. The helper resizes the figure only to the `WidthInches`/`HeightInches` you pass (otherwise it keeps the current size) and keeps each layout's `TileSpacing`/`Padding` unless you pass `TileSpacing=`/`LayoutPadding=`, so make size and spacing changes there or in the `tiledlayout` call. (If you would rather not depend on the helper, set the size yourself with `figure('Units', 'inches', 'Position', [1 1 6.5 4.5])` and use the two `exportgraphics` lines in step 3.)

## Common Defects → Fix

Look for these in the rendered PNG; read [`references/matlab_figure_guidelines.md`](./references/matlab_figure_guidelines.md) for the full rules and rationale before styling.

- Cramped panels → increase `HeightInches` before shrinking fonts.
- Tiny text after LaTeX scaling → export at the final include width so LaTeX needs no scaling.
- Legend stealing plot area → one shared legend docked outside the tiles (`lgd.Layout.Tile = 'south'`).
- Thin lines / small markers after scaling → raise line width and marker size.
- Crowded or rainbow colors → one concept per color, colorblind-safe palette; `parula` (default) or `sky` (R2023a+) for continuous data, not `jet`. MATLAB has no built-in `viridis` or `cividis`.
- Crowded ticks or a corner `1e4` multiplier → sparse explicit ticks; `ax.YAxis.Exponent = 0`.
- Clipped titles or labels → loosen `TileSpacing`/`Padding` (in `tiledlayout`, or pass them to the helper).
- Dark plot box with gray text (R2025a+ dark theme) → `theme(fig, "light")` before export; the helper does this.
- Mixed fonts in the PDF from `text()` or `xline`/`yline` labels → `fontname(fig, "Arial")` (R2022a+); the helper does this.

## Decisions

- Refactor an existing `.m` in place: preserve the data and computation, change only styling and layout.
- Move `subplot` to `tiledlayout` unless rewriting would risk the user's intent on code they want minimally touched.
- Default to vector PDF. If a layer has many thousands of primitives and the PDF becomes huge or slow to compile, first cut the primitive count (`imagesc` instead of `pcolor` or a flat `surf`, `binscatter` instead of a dense `scatter`), which keeps all text vector. `ContentType='image'` rasterizes everything in that export, text included, so otherwise export the heavy panel alone as an image and assemble the panels in LaTeX, or export the whole figure as an image at 300–600 DPI.

## Helper

[`scripts/export_publication_figure.m`](./scripts/export_publication_figure.m) applies the final size you pass, readable font and line defaults, one font across all text, and the vector-PDF + PNG-preview export. Copy it into the project, or add its folder to the MATLAB path (`addpath(fullfile('${CLAUDE_SKILL_DIR}', 'scripts'))`) before calling it, as in the recipe above.

## Report Back

- State what changed in the MATLAB code.
- Cite the exact PNG path you read and at least one concrete thing you observed and acted on (e.g. "legend overlapped Panel B, moved it outside"). If you could not render or read it, say so and state what remains unverified.
- Mention any remaining limitations, warnings, or assumptions.

## Resources

- [`scripts/export_publication_figure.m`](./scripts/export_publication_figure.m): reusable export helper for publication-style figures.
- [`references/matlab_figure_guidelines.md`](./references/matlab_figure_guidelines.md): structural, color, sizing, and layout conventions — read before styling.
- [`references/render_review_checklist.md`](./references/render_review_checklist.md): the post-export visual checklist — work through it before declaring the figure done.
