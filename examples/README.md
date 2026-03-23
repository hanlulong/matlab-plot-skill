# Examples

This folder contains small runnable examples that demonstrate the intended output quality and workflow for the skill.

## Demo Figure

Run:

```powershell
matlab -batch "run('examples/demo_publication_figure.m')"
```

This generates:

- `examples/output/demo_publication_figure.pdf`
- `examples/output/demo_publication_figure.png`

The PNG is for quick visual inspection. The PDF is the publication-style export for LaTeX or Overleaf.

The point of the example is not the data. It demonstrates the workflow the skill should enforce:

1. make the figure,
2. export the vector PDF,
3. read the rendered result,
4. iterate until the layout is no longer messy.
