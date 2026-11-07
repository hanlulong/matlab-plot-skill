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

By default `exportgraphics` crops the export to its content, so the PDF comes out about 5–15% smaller than the figure (on R2026a a 6.5 x 4 in figure with one axes exports at about 5.6 x 3.8 in), and `width=\linewidth` then enlarges the text by the same amount. From R2025a, pass the size to `exportgraphics` as well:

```matlab
exportgraphics(fig, 'fig.pdf', 'ContentType', 'vector', ...
    'Width', 3.49, 'Height', 2.6, 'Units', 'inches');
```

Use the figure's own size for `Width` and `Height` (`exportgraphics` re-lays the content out into that box, and MathWorks advises a figure of similar size and aspect ratio). The page is then exactly that size and, for a figure built at that size, text prints within about 1% of its point size. The helper does this on R2025a+. It also fixes the page size in a case seen on R2026a: a figure resized after it was drawn (for example, re-exported at a slide size after the paper size) can otherwise export at its previous size. Text in such a re-export can still be 1–3% off its point size (measured on R2026a), so build a fresh figure for each target size when exact point sizes matter. In installed MATLAB R2021a–R2024b these options do not exist (MATLAB Online has them from R2024a), so include the cropped PDF at its natural size (`\includegraphics{fig.pdf}`) when exact point sizes matter. Check the result with `pdfinfo fig.pdf`: the `Page size` line is in points, so divide by 72 to get inches.

## Style Defaults

- Start with line widths around `1.2` to `1.5`.
- Start with marker sizes around `6` to `8`.
- Keep axis fonts and legend fonts readable after expected page scaling.
- Use `Arial` rather than `Helvetica` for cross-platform consistency: Helvetica is effectively macOS-only and is silently substituted (usually by Arial) on Windows and Linux, which can change glyphs and metrics in the exported PDF.
- Use one font for all text. Styling axes does not reach `text()` annotations or `xline`/`yline` labels, which keep MATLAB's default font and leave the PDF with mixed fonts. `fontname(fig, "Arial")` (R2022a+) sets every text object in the figure; on older releases use `set(findall(fig, '-property', 'FontName'), 'FontName', 'Arial')`. The helper does this. Text with `Interpreter='latex'` is the exception: MATLAB always typesets it in Computer Modern (`pdffonts` lists `mwa_cmr10`/`mwa_cmmi10`), which is expected for math labels. Use the `tex` interpreter (`'\pi_t'`) when a label should match the figure font.
- Export light figures. From R2025a a figure follows the MATLAB desktop theme by default, so a dark desktop gives dark figures that export gray text on a black plot box. Call `theme(fig, "light")` before export; the helper does this. Under `matlab -batch` new figures are light.

## Color

- Keep the number of colors low and map one concept to one color across the full figure.
- Use a colorblind-safe categorical palette for line/marker series. The Okabe–Ito palette is a good default (~8% of male readers have red–green deficiency). For lines and markers on white, use this order, which puts the five colors with at least 3:1 contrast against white (the WCAG minimum for graphics) first and leaves out yellow (1.3:1, nearly invisible as a line):

  ```matlab
  okabeIto = [ ...
        0 114 178;   % blue
      213  94   0;   % vermillion
        0 158 115;   % bluish green
      204 121 167;   % reddish purple
        0   0   0;   % black
      230 159   0;   % orange (2.3:1, pair with markers)
       86 180 233] / 255;   % sky blue (2.3:1, pair with markers)
  colororder(fig, okabeIto);   % right after fig = figure, before plotting (R2019b+)
  ```

  Set the order on the figure: it applies to every axes in that figure and persists through later plotting calls. Avoid `set(groot, 'defaultAxesColorOrder', ...)`, which changes every later figure in the MATLAB session (for example the next script in a replication run). A per-axes order (`colororder(ax, ...)` or `ax.ColorOrder = ...`) is replaced by the next plotting call unless `hold(ax, 'on')` comes first.

  Use Okabe–Ito yellow (`[240 228 66] / 255`) only for filled areas or bars, or give it a dark edge. MATLAB's default blue/orange (about `[0 0.447 0.741]` / `[0.85 0.325 0.098]`) is already reasonably colorblind-safe; red/green pairings are not.
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

On R2025a+ add `'Width', w, 'Height', h, 'Units', 'inches'` so the PDF is the final size instead of a tight crop (see [Sizing And Page Fit](#sizing-and-page-fit)).

`exportgraphics` chooses vector vs. raster output via `ContentType` and **ignores the figure `Renderer` property** — there is no renderer to set for the PDF. (`set(gcf, 'Renderer', ...)` only affects on-screen drawing and the legacy `print`/`saveas` paths.)

EPS has no transparency: MATLAB writes a `FaceAlpha` band to EPS as an opaque, pre-blended fill (seen on R2026a), which hides grid lines and any band underneath. Prefer PDF; if a journal requires EPS, draw the wider band first so the narrower one stays visible.

Always inspect the exported PDF. Even when `exportgraphics(..., 'ContentType', 'vector')` is the right default, some MATLAB versions or graphics objects can still produce artifacts or awkward text handling.

If figure-level PDF export looks wrong:

- call `exportgraphics` directly on the `tiledlayout` or `axes` handle (the helper accepts only a figure handle),
- if a figure whose axes sit in two or more `uipanel`s or tabs fails to export (seen on R2026a, with an error that begins "Figure has more than one container"), export each container with `exportgraphics`, or rebuild the panels as tiles of one `tiledlayout`,
- inspect the standalone PDF and the final LaTeX page,
- generate a PNG review export so you can read the figure quickly during iteration.

### PDF Internals To Verify

- Select text in the exported PDF: it should be selectable vector text with embedded fonts, not a rasterized image and not outlined curves.
- Check that negative numbers render with a visible sign. MATLAB writes negative tick labels with the ASCII hyphen-minus (U+002D), not the typographic minus (U+2212) (checked on R2026a). If the journal's style requires a true minus, relabel those ticks deliberately.

## Rasterizing Heavy Figures

A vector PDF is the wrong choice for figures with many thousands of primitives (dense scatter, large `pcolor`/`surf`/`contourf`, maps): the file balloons and Overleaf compiles slowly. The symptom is a multi-megabyte PDF or a slow compile. (On R2026a, at 6.5 x 4 in, a 400 x 400 `pcolor` exports to about 2–4 MB, depending on the data, and a 200,000-point `scatter` to 15 MB or more.)

`exportgraphics(..., 'ContentType', 'image')` rasterizes **everything** in that export, including tick labels, titles, and legends; the PDF then contains no fonts at all. There is no setting that rasterizes one panel while keeping the rest of the same export vector. In order of preference:

1. Reduce the number of primitives so the vector export stays small and all text stays vector: draw gridded data with `imagesc`/`image` instead of `pcolor` or a flat `surf` (the data is embedded as a bitmap while text stays vector; the same 400 x 400 grid exports to tens of KB for a smooth surface and a few hundred KB for random noise, which compresses poorly, depending on the figure size), and replace dense scatters with `binscatter`, `histogram2`, or a downsample.
2. Export the heavy panel on its own as an image (`exportgraphics(ax, 'panel.png', 'Resolution', 300)` or an image-only PDF) and assemble it with the vector panels in LaTeX, for example with `subcaption`.
3. Export the whole figure with `ContentType='image'` at 300–600 DPI and accept raster text. The helper exports images at exportgraphics' default 150 dpi, so run the helper first (it styles the figure), then call `exportgraphics(fig, 'fig.pdf', 'ContentType', 'image', 'Resolution', 300)` directly, adding `'Width', w, 'Height', h, 'Units', 'inches'` on R2025a+. On R2026a the image in such a PDF is JPEG-compressed.

## Layout Rules

- `TileSpacing='compact'` and `Padding='compact'` are good starting points, not mandatory end states. The helper keeps whatever the `tiledlayout` call set unless you pass `TileSpacing=`/`LayoutPadding=` to it.
- Loosen spacing when titles, legends, or panel headers start to collide.
- Remove redundant y-axis labels or repeated legends before removing information.
- For one shared legend, create it on any axes and dock it outside all panels: `lgd = legend(...); lgd.Layout.Tile = 'south';` (or `'east'`/`'north'`, R2020b+). This reserves space around the whole layout, unlike `'Location','southoutside'`, which only steals area from a single tile.

## Ticks And Number Formatting

- When auto-ticks crowd, set a sparse explicit vector: `xticks(0:0.25:1)` or `set(ax, 'YTick', ...)`.
- Kill the corner axis multiplier (the `1e4` parked above the axis): `ax.YAxis.Exponent = 0;` (or relabel deliberately).
- `TickLabelFormat` formats the values shown next to the x10^n multiplier, not the raw values. For a format written for the raw values (always the case with a thousands separator such as `'%,.0f'`), set `ax.YAxis.Exponent = 0` first. Otherwise a 0-250,000 axis shown with a x10^5 multiplier prints 0 | 1 | 1 | 2 | 2 | 3 (seen on R2026a). Choose the decimals for the values actually shown (for example `'%.1f'`), and check the PNG for repeated tick labels.
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
