# MATLAB Figure Guidelines

## Structural Defaults

- Prefer `tiledlayout` to `subplot` for any serious multi-panel figure.
- Use shared legends when several panels show the same series definitions.
- Use explicit figure dimensions in inches.
- Use vector PDF export for papers and Overleaf workflows.
- Requires MATLAB R2020a+ for `exportgraphics`; `tiledlayout` needs R2019b+.

## Sizing And Page Fit

Size the figure for its **final printed dimensions**, then size fonts and line widths for that size. The reliable rule: export at the exact target width and include it in LaTeX at scale 1.0 (`\includegraphics[width=\columnwidth]{...}` or `width=\textwidth`), so the page does no scaling.

- Single journal column: about `3.3`–`3.5` in wide.
- Full text width: about `6.5` in wide (depends on the document class).
- If you must let LaTeX downscale by a factor `s`, multiply font sizes and line widths by `1/s` so they hit the page at the intended size. A 10 pt label exported at 7 in and then shown at `\columnwidth` (~3.3 in) lands at ~4.7 pt — below most journals' ~6–8 pt floor.

Prefer a taller canvas over tiny fonts when the figure feels cramped.

To get the exact target width, read it from the document: add `\showthe\columnwidth` (or `\the\columnwidth`) to the `.tex` and compile. Convert TeX points to inches with 1 in = 72.27 pt (not 72), then export at that width and include at scale 1.0:

```matlab
% \showthe\columnwidth printed 252.0pt  ->  252.0 / 72.27 = 3.49 in
export_publication_figure(fig, 'fig.pdf', WidthInches=3.49);
```

```latex
\includegraphics[width=\columnwidth]{fig.pdf}   % no scale factor
```

Two-column classes (IEEEtran, RevTeX twocolumn) have a much narrower `\columnwidth` than `\textwidth`.

## Style Defaults

- Start with line widths around `1.2` to `1.5`.
- Start with marker sizes around `6` to `8`.
- Keep axis fonts and legend fonts readable after expected page scaling.
- Use `Arial` rather than `Helvetica` for cross-platform consistency: Helvetica is effectively macOS-only and is silently substituted (usually by Arial) on Windows and Linux, which can change glyphs and metrics in the exported PDF.

## Color

- Keep the number of colors low and map one concept to one color across the full figure.
- Use a colorblind-safe categorical palette for line/marker series. The Okabe–Ito 8-color set is a good default (~8% of male readers have red–green deficiency):

  ```matlab
  okabeIto = [ ...
      0.00 0.45 0.70;   % blue
      0.90 0.62 0.00;   % orange
      0.00 0.62 0.45;   % bluish green
      0.80 0.47 0.65;   % reddish purple
      0.95 0.90 0.25;   % yellow
      0.34 0.71 0.91;   % sky blue
      0.84 0.37 0.00;   % vermillion
      0.00 0.00 0.00];  % black
  set(groot, 'defaultAxesColorOrder', okabeIto);   % or per-axes: ax.ColorOrder = okabeIto
  ```

  MATLAB's default blue/orange (`[0 0.447 0.741]` / `[0.85 0.325 0.098]`) is already reasonably colorblind-safe; red/green pairings are not.
- For continuous data (heatmaps, surfaces, `pcolor`), use a perceptually uniform sequential colormap such as `parula` (default), `viridis`, or `cividis`. Avoid `jet` and `hsv`.
- Make series distinguishable in grayscale too: pair color with marker shape or line style.

## Uncertainty

- Prefer a shaded confidence band over a forest of error bars for dense series: draw a `patch`/`fill` with `FaceAlpha` ~0.15–0.2, no edge, the same hue as the mean line, *before* the line so the line sits on top.
- Use error bars for sparse categorical data; keep cap widths modest and avoid overlapping caps.
- Match the band or error color to the series color so the uncertainty reads as belonging to that series.

## Export Defaults

Use:

```matlab
exportgraphics(gcf, outputPath, 'ContentType', 'vector', 'BackgroundColor', 'white');
```

`exportgraphics` chooses vector vs. raster output via `ContentType` and **ignores the figure `Renderer` property** — there is no renderer to set for the PDF. (`set(gcf, 'Renderer', ...)` only affects on-screen drawing and the legacy `print`/`saveas` paths.)

Always inspect the exported PDF. Even when `exportgraphics(..., 'ContentType', 'vector')` is the right default, some MATLAB versions or graphics objects can still produce artifacts or awkward text handling.

If figure-level PDF export looks wrong:

- try exporting the `tiledlayout` or `axes` handle directly,
- inspect the standalone PDF and the final LaTeX page,
- generate a PNG review export so you can read the figure quickly during iteration.

### PDF Internals To Verify

- Select text in the exported PDF: it should be selectable vector text with embedded fonts, not a rasterized image and not outlined curves.
- Check that minus signs and negative numbers render. MATLAB uses the Unicode minus (U+2212), which some viewers or LaTeX font setups drop or show as a missing-glyph box; switch the font or reformat the affected labels if so.

## Rasterizing Heavy Figures

A vector PDF is the wrong choice for figures with many thousands of primitives (dense scatter, large `pcolor`/`surf`/`contourf`, maps): the file balloons and Overleaf compiles slowly. The symptom is a multi-megabyte PDF or a slow compile.

- Export the heavy panel as raster while keeping the rest vector: `exportgraphics(ax, 'panel.pdf', 'ContentType', 'image', 'Resolution', 300)` (300–600 DPI).
- Or accept raster text for the whole figure with `ContentType='image'` at high resolution.

Keep axes, ticks, labels, and legends vector wherever the data layer allows.

## Layout Rules

- `TileSpacing='compact'` and `Padding='compact'` are good starting points, not mandatory end states.
- Loosen spacing when titles, legends, or panel headers start to collide.
- Remove redundant y-axis labels or repeated legends before removing information.
- For one shared legend, create it on any axes and dock it outside all panels: `lgd = legend(...); lgd.Layout.Tile = 'south';` (or `'east'`/`'north'`, R2020b+). This reserves space around the whole layout, unlike `'Location','southoutside'`, which only steals area from a single tile.

## Ticks And Number Formatting

- When auto-ticks crowd, set a sparse explicit vector: `xticks(0:0.25:1)` or `set(ax, 'YTick', ...)`.
- Kill the corner axis multiplier (the `1e4` parked above the axis): `ax.YAxis.Exponent = 0;` (or relabel deliberately).
- Force consistent decimals or thousands separators: `ax.YAxis.TickLabelFormat = '%.1f';` (or `'%,.0f'`).
- Avoid rotated x tick labels except for long categorical names.

## Title Rules

- Keep subplot titles short and use regular weight; reserve bold for a panel letter (A, B, C) rather than bolding every descriptive title.
- Use panel-level headers for repeated context.
- Increase title font size when the figure is intended for print or PDF reading.

## Reproducibility

- Keep the plotting `.m` runnable end-to-end so the figure can be regenerated from source.
- Seed `rng(...)` before any randomly generated data.
- Avoid manual figure tweaks the script cannot reproduce.

## Final Step

Always read the generated figure yourself (read the PNG preview; you cannot visually inspect a vector PDF directly). If the figure will appear inside a paper, read the compiled page too, then iterate.
