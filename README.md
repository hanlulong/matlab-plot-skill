# MATLAB Plot Skill

`matlab-plot-skill` is a reusable skill for Codex and Claude Code that helps agents produce publication-quality MATLAB figures.

The key rule is simple: the agent must not stop after writing plotting code. It must generate the figure, export it, read the rendered figure itself, and iterate until the visual result is professional.

## What This Skill Enforces

- MATLAB-first figure cleanup for papers, appendices, and slides
- vector PDF export for LaTeX and Overleaf workflows
- better layout choices for multi-panel figures
- explicit render-review-iterate behavior
- reusable MATLAB export helper code

## Repository Layout

- [`matlab-plot-skill/SKILL.md`](./matlab-plot-skill/SKILL.md)
- [`matlab-plot-skill/scripts/export_publication_figure.m`](./matlab-plot-skill/scripts/export_publication_figure.m)
- [`matlab-plot-skill/references/render_review_checklist.md`](./matlab-plot-skill/references/render_review_checklist.md)
- [`matlab-plot-skill/references/matlab_figure_guidelines.md`](./matlab-plot-skill/references/matlab_figure_guidelines.md)
- [`install.ps1`](./install.ps1)
- [`install.sh`](./install.sh)

## Install

### Windows PowerShell

Install into both Codex and Claude Code skill directories:

```powershell
.\install.ps1
```

Install only into Codex:

```powershell
.\install.ps1 -Target codex
```

Overwrite an existing installed copy:

```powershell
.\install.ps1 -Force
```

### macOS / Linux

```bash
./install.sh
```

Install only into Claude Code:

```bash
./install.sh --target claude
```

## Manual Install

Copy the [`matlab-plot-skill`](./matlab-plot-skill) folder into one or both of these locations:

- Codex: `~/.codex/skills/matlab-plot-skill`
- Claude Code: `~/.claude/skills/matlab-plot-skill`

## Example Invocation

Use prompts like:

```text
Use $matlab-plot-skill to refactor Plots/generate_my_figure.m into a publication-quality PDF figure. Read the exported figure and the compiled paper page, then iterate until the spacing and titles are clean.
```

```text
Use $matlab-plot-skill to improve this MATLAB appendix figure. Keep the color mapping fixed across panels, distinguish variants with markers, export a vector PDF, and read the generated figure yourself before stopping.
```

## Notes

- Codex reads [`agents/openai.yaml`](./matlab-plot-skill/agents/openai.yaml) for optional UI metadata.
- Claude Code can use the same `SKILL.md`-based folder structure.
