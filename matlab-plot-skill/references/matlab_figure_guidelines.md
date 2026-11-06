# MATLAB Figure Guidelines

## Contents

- [Structural Defaults](#structural-defaults)
- [Sizing And Page Fit](#sizing-and-page-fit)
- [Style Defaults](#style-defaults)
- [Color](#color)
- [Uncertainty](#uncertainty)
- [Export Defaults](#export-defaults)
- [Rasterizing Heavy Figures](#rasterizing-heavy-figures)
- [Layout Rules](#layout-rules)
- [Ticks And Number Formatting](#ticks-and-number-formatting)
- [Title Rules](#title-rules)
- [Reproducibility](#reproducibility)
- [Final Step](#final-step)

## Structural Defaults

- Prefer `tiledlayout` to `subplot` for any serious multi-panel figure.
- Use shared legends when several panels show the same series definitions.
- Use explicit figure dimensions in inches.
- Use vector PDF export for papers and Overleaf workflows.
- Requires MATLAB R2021a+ for the helper and the name=value call syntax used here (`exportgraphics` is R2020a+, `tiledlayout` R2019b+). `fontname` needs R2022a+, `sky` R2023a+, and figure themes R2025a+.

## Sizing And Page Fit

Size the figure for its **final printed dimensions**, then size fonts and line widths for that size. The reliable rule: export at the exact width the document includes it at (`\includegraphics[width=\linewidth]{...}`, `width=\columnwidth`, `width=\textwidth`, or a fraction of one) and pass both `WidthInches` and `HeightInches` to the helper, so the page does no scaling.

`\columnwidth` is only narrow in two-column layouts. In a one-column document it equals `\textwidth`, so a figure exported at a "single column" 3.3 in and included at `\columnwidth` gets scaled up about 1.4–2x, with oversized fonts and lines. Typical widths (TeX Live 2025, letter paper; 1 in = 72.27 pt):

| Document | Include width | Inches |
|---|---|---|
| `article`, 10 / 11 / 12 pt, default margins | `\textwidth` = `\columnwidth` = 345 / 360 / 390 pt | 4.77 / 4.98 / 5.40 |
| `article` with `geometry` `margin=1in` | `\textwidth` = `\columnwidth` = 469.75 pt | 6.50 |
| `article`, `twocolumn` | `\columnwidth` = 229.5 pt | 3.18 |
| `IEEEtran` (two-column default) | `\columnwidth` = 252 pt | 3.49 |
| `revtex4-2`, `twocolumn` | `\columnwidth` = 246 pt | 3.40 |
| `beamer` 4:3 / `aspectratio=169` | `\textwidth` = 307.29 / 398.34 pt | 4.25 / 5.51 |

Journal templates and custom margins change these numbers, so measure when it matters.

- If you must let LaTeX downscale by a factor `s`, multiply font sizes and line widths by `1/s` so they hit the page at the intended size. A 10 pt label exported at 7 in and then shown at a 3.3 in column lands at ~4.7 pt — below most journals' ~6–8 pt floor.

Prefer a taller canvas (`HeightInches`) over tiny fonts when the figure feels cramped.

To get the exact target width, read it from the document: put `\typeout{\the\linewidth}` inside the figure environment that includes the graphic (there `\linewidth` is the column width, or the full text width in `figure*`), compile, and read the value from the log. Convert TeX points to inches with 1 in = 72.27 pt (not 72), then export at that width and include at scale 1.0:

```matlab
% \typeout{\the\linewidth} logged 252.0pt  ->  252.0 / 72.27 = 3.49 in
export_publication_figure(fig, 'fig.pdf', WidthInches=3.49, HeightInches=2.6);
```

```latex
\includegraphics[width=\linewidth]{fig.pdf}   % no scale factor
```

`exportgraphics` crops to a thin margin around the content by default, so the PDF comes out slightly smaller than the figure (the repo's 6.5 x 5 in demo exports at about 6.2 x 4.9 in). Including it at `width=\linewidth` therefore scales it up by a few percent, which is harmless; include it at natural size (`\includegraphics{fig.pdf}`) when exact point sizes matter.

## Style Defaults

- Start with line widths around `1.2` to `1.5`.
- Start with marker sizes around `6` to `8`.
- Keep axis fonts and legend fonts readable after expected page scaling.
- Use `Arial` rather than `Helvetica` for cross-platform consistency: Helvetica is effectively macOS-only and is silently substituted (usually by Arial) on Windows and Linux, which can change glyphs and metrics in the exported PDF.
- Use one font for all text. Styling axes does not reach `text()` annotations or `xline`/`yline` labels, which keep MATLAB's default font and leave the PDF with mixed fonts. `fontname(fig, "Arial")` (R2022a+) sets every text object in the figure; on older releases use `set(findall(fig, '-property', 'FontName'), 'FontName', 'Arial')`. The helper does this.
- Export light figures. From R2025a a figure follows the MATLAB desktop theme by default, so a dark desktop gives dark figures that export gray text on a black plot box. Call `theme(fig, "light")` before export; the helper does this. Under `matlab -batch` new figures are light.

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
- For continuous data (heatmaps, surfaces, `pcolor`), use a sequential built-in colormap: `parula` (the default) or `sky` (R2023a+, light to dark blue), or `gray` for print. `turbo` (R2020b+) is a smoother rainbow than `jet` for data that needs many distinct hues, but it is not perceptually uniform. Avoid `jet` and `hsv`. MATLAB has no built-in `viridis`, `cividis`, `magma`, or `plasma`: `colormap(viridis)` fails with "Unrecognized function or variable", so do not call them unless the project already defines them.
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

A vector PDF is the wrong choice for figures with many thousands of primitives (dense scatter, large `pcolor`/`surf`/`contourf`, maps): the file balloons and Overleaf compiles slowly. The symptom is a multi-megabyte PDF or a slow compile. (On R2026a, a 400 x 400 `pcolor` exports to about 2-4 MB, depending on the data, and a 200,000-point `scatter` to about 32 MB.)

`exportgraphics(..., 'ContentType', 'image')` rasterizes **everything** in that export, including tick labels, titles, and legends; the PDF then contains no fonts at all. There is no setting that rasterizes one panel while keeping the rest of the same export vector. In order of preference:

1. Reduce the number of primitives so the vector export stays small and all text stays vector: draw gridded data with `imagesc`/`image` instead of `pcolor` or a flat `surf` (the data is embedded as a bitmap while text stays vector; the same 400 x 400 grid exports to about 25 KB for a smooth surface and about 150 KB for random noise, which compresses poorly), and replace dense scatters with `binscatter`, `histogram2`, or a downsample.
2. Export the heavy panel on its own as an image (`exportgraphics(ax, 'panel.png', 'Resolution', 300)` or an image-only PDF) and assemble it with the vector panels in LaTeX, for example with `subcaption`.
3. Export the whole figure with `ContentType='image'` at 300–600 DPI and accept raster text.

## Layout Rules

- `TileSpacing='compact'` and `Padding='compact'` are good starting points, not mandatory end states. The helper keeps whatever the `tiledlayout` call set unless you pass `TileSpacing=`/`LayoutPadding=` to it.
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
