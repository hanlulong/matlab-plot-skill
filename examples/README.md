# Examples

This folder contains small runnable examples that demonstrate the intended output quality and workflow for the skill.

## Demo Figure

Run this from the repository root (the path is relative to MATLAB's working directory):

```bash
matlab -batch "run('examples/demo_publication_figure.m')"
```

This generates:

- `examples/output/demo_publication_figure.pdf`
- `examples/output/demo_publication_figure.png`

The PNG is for quick visual inspection. The PDF is the publication-style export for LaTeX or Overleaf. Only the PNG is committed to the repo; the PDF is produced locally. Regenerate the committed PNG whenever you change the demo or the export helper.

The demo follows the skill's own rules: it exports at its final printed size (6.5 x 5 in, the text width of a 1-in-margin letter page; at `width=\linewidth` LaTeX enlarges it only by the few percent that `exportgraphics` crops off the margins), maps one color to one concept (inflation blue, output orange) in every panel, uses a single shared legend docked to the layout (`lgd.Layout.Tile = 'north'`) and a shared x label, and labels the panels A-C. Size and spacing are set once, in `figure`/`tiledlayout` and the helper's `WidthInches`/`HeightInches`; the helper keeps the layout spacing the demo chose.

The point of the example is not the data. It demonstrates the workflow the skill should enforce:

1. make the figure,
2. export the vector PDF,
3. read the rendered result,
4. iterate until the layout is no longer messy.
