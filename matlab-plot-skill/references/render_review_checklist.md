# Render Review Checklist

Use this checklist after exporting the figure. Read the actual rendered figure before deciding the work is finished — read the PNG preview, since a vector PDF cannot be inspected visually as an image.

## Always Check

- Is the aspect ratio appropriate, or does the figure look too short or too wide?
- Does the figure fill the intended page space without feeling crowded?
- Are subplot titles readable at final page scale?
- Are font sizes consistent across axes, legends, and titles?
- Is the figure light (white background, dark text), not a dark-theme export?
- Are lines thick enough and markers large enough after scaling?
- Are related series easy to distinguish in grayscale and color? To see it, make a gray copy and read that too: `pdftoppm -png -gray -r 200 -singlefile out/figure.pdf out/figure_gray` (Poppler), or append `imwrite(im2gray(imread('out/figure.png')), 'out/figure_gray.png')` (R2020b+) to the `matlab -batch` call that renders the figure.
- Is the legend easy to scan without shrinking the data region too much?
- Is every band you drew visible, and does the legend list only real series (no `data1` entries)?
- Are any tick labels, titles, or legends clipped?
- Are there unnecessary repeated axis labels or repeated legends?
- Do panel headings and subplot titles create a clear hierarchy?

## Multi-Panel Checks

- Are panel gaps large enough to separate ideas clearly?
- Are tiles aligned cleanly?
- Are axis limits and tick conventions consistent when they should be?
- Is color meaning stable across all panels?
- Are markers or line styles doing the secondary differentiation work?

## Honest Encoding

Check these and tell the user when one fails. Change the figure only when the fix is clearly what the user intends; do not change their data, chart type, or caption on your own.

- Does the legend, a panel note, or the caption say what each band or error bar is (for example 68% and 90% intervals, or ±1 SE)? If the code does not say, ask rather than guess; if the caption is the user's, point out the gap instead of writing the caption.
- Do color-mapped panels that readers will compare share one color scale and one labeled colorbar? For axes plots (`imagesc`, `pcolor`, `surf`, `contourf`), use `set([ax1 ax2], 'CLim', [lo hi])` and one colorbar docked to the layout (`cb.Layout.Tile = 'east'`; checked on R2026a). For `heatmap` charts, set the same `ColorLimits` on each chart.
- Do missing values show as gaps rather than being bridged or silently dropped? For bands with NaN bounds, see [Uncertainty](./matlab_figure_guidelines.md#uncertainty).
- Do bars start at zero, and does `yyaxis` show only series in different units, with both sides labeled? If not, tell the user rather than changing it.

## PDF Internals

- Select text in the PDF to confirm it is vector text with embedded fonts, not a rasterized image.
- Check the page size: `pdfinfo figure.pdf` prints `Page size` in points, which divided by 72 should give the final width and height in inches. Before R2025a it is a tight crop, about 5–15% smaller.
- Check that all text uses one font family (`pdffonts figure.pdf` should list one family, e.g. only Arial); `text()` and `xline`/`yline` labels are the usual strays. Text with `Interpreter='latex'` is always typeset in Computer Modern (`mwa_cmr10`, `mwa_cmmi10` in `pdffonts`); that is expected, so keep LaTeX math labels the user chose. Switch a label to the `tex` interpreter (`'\pi_t'`) only when it should match the figure font. Labels in Chinese, Japanese or Korean add a system fallback font (PingFang SC on macOS, seen on R2026a; other platforms not checked); that is expected, so do not try to remove it.
- Check that negative numbers render with a visible sign (MATLAB writes the ASCII hyphen-minus; checked on R2026a).

## Embedded Figure Checks

- Read the compiled paper page, not just the standalone PDF.
- Check whether LaTeX scaling made text too small or too large (a figure exported narrower than its include width gets scaled up).
- Check whether the caption and notes compete visually with the figure.
- Check whether the figure placement causes awkward whitespace on the page.

## Typical Iterations

- Increase physical height (`HeightInches`) if the figure feels compressed.
- Increase outer spacing if panel headers collide with titles.
- Shorten titles before reducing font size.
- Move legends outside the tightest panel group.
- Reduce decorative clutter before reducing information.
