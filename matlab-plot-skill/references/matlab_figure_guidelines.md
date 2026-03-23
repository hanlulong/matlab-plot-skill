# MATLAB Figure Guidelines

## Structural Defaults

- Prefer `tiledlayout` to `subplot` for any serious multi-panel figure.
- Use shared legends when several panels show the same series definitions.
- Use explicit figure dimensions in inches.
- Use vector PDF export for papers and Overleaf workflows.

## Style Defaults

- Start with line widths around `1.2` to `1.5`.
- Start with marker sizes around `6` to `8`.
- Keep axis fonts and legend fonts readable after expected page scaling.
- Keep the number of colors low and meaningful.
- Map one concept to one color across the full figure.

## Export Defaults

Use:

```matlab
exportgraphics(gcf, outputPath, 'ContentType', 'vector', 'BackgroundColor', 'white');
```

Set the renderer explicitly when helpful:

```matlab
set(gcf, 'Renderer', 'painters');
```

Always inspect the exported PDF. Even when `exportgraphics(..., 'ContentType', 'vector')` is the right default, some MATLAB versions or graphics objects can still produce artifacts or awkward text handling.

If figure-level PDF export looks wrong:

- try exporting the `tiledlayout` or `axes` handle directly,
- inspect the standalone PDF and the final LaTeX page,
- generate a PNG review export so you can read the figure quickly during iteration.

## Layout Rules

- `TileSpacing='compact'` and `Padding='compact'` are good starting points, not mandatory end states.
- Loosen spacing when titles, legends, or panel headers start to collide.
- Prefer a taller canvas over tiny fonts when the figure feels cramped.
- Remove redundant y-axis labels or repeated legends before removing information.

## Title Rules

- Keep subplot titles short.
- Use panel-level headers for repeated context.
- Increase title font size when the figure is intended for print or PDF reading.

## Final Step

Always read the generated figure yourself. If the figure will appear inside a paper, read the compiled page too, then iterate.
