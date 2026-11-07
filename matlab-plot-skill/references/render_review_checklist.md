# Render Review Checklist

Use this checklist after exporting the figure. Read the actual rendered figure before deciding the work is finished — read the PNG preview, since a vector PDF cannot be inspected visually as an image.

## Always Check

- Is the aspect ratio appropriate, or does the figure look too short or too wide?
- Does the figure fill the intended page space without feeling crowded?
- Are subplot titles readable at final page scale?
- Are font sizes consistent across axes, legends, and titles?
- Is the figure light (white background, dark text), not a dark-theme export?
- Are lines thick enough and markers large enough after scaling?
- Are related series easy to distinguish in grayscale and color?
- Is the legend easy to scan without shrinking the data region too much?
- Are any tick labels, titles, or legends clipped?
- Are there unnecessary repeated axis labels or repeated legends?
- Do panel headings and subplot titles create a clear hierarchy?

## Multi-Panel Checks

- Are panel gaps large enough to separate ideas clearly?
- Are tiles aligned cleanly?
- Are axis limits and tick conventions consistent when they should be?
- Is color meaning stable across all panels?
- Are markers or line styles doing the secondary differentiation work?

## PDF Internals

- Select text in the PDF to confirm it is vector text with embedded fonts, not a rasterized image.
- Check the page size: `pdfinfo figure.pdf` prints `Page size` in points, which divided by 72 should give the final width and height in inches. Before R2025a it is a tight crop, about 5–15% smaller.
- Check that all text uses one font family (`pdffonts figure.pdf` should list one family, e.g. only Arial); `text()` and `xline`/`yline` labels are the usual strays. Text with `Interpreter='latex'` is always typeset in Computer Modern (`mwa_cmr10`, `mwa_cmmi10` in `pdffonts`); that is expected, so keep LaTeX math labels the user chose. Switch a label to the `tex` interpreter (`'\pi_t'`) only when it should match the figure font.
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
