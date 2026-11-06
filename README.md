# Publication-Quality MATLAB Figures

`matlab-plot-skill` is a reusable skill for Codex and Claude Code that fixes messy MATLAB figures: cramped layouts, unreadable titles, awkward legends, bad white space, and weak PDF output for LaTeX or Overleaf.

The key rule is simple: the agent must not stop after writing plotting code. It must generate the figure, export it, read the rendered figure itself, and iterate until the visual result is no longer a mess.

![Demo figure](./examples/output/demo_publication_figure.png)

## Find This Repo If You Searched For

- how to make MATLAB figures look professional
- publication-quality MATLAB plots
- fix messy subplot layout in MATLAB
- export MATLAB figure to PDF for LaTeX
- MATLAB figures for Overleaf
- improve MATLAB legend, title, spacing, and white space

## What Problem This Solves

- multi-panel MATLAB figures that look cramped or amateurish
- legends that steal too much plot area
- titles that are too long or too small after PDF scaling
- inconsistent colors and symbols across panels
- plots that look acceptable in MATLAB but bad once embedded in a paper

## What This Skill Enforces

- MATLAB-first figure cleanup for papers, appendices, and slides
- vector PDF export for LaTeX and Overleaf workflows
- better layout choices for multi-panel figures
- explicit render-review-iterate behavior
- reusable MATLAB export helper code
- a quick PNG review path so the agent can read the rendered figure easily

## Repository Layout

- [`matlab-plot-skill/SKILL.md`](./matlab-plot-skill/SKILL.md)
- [`matlab-plot-skill/scripts/export_publication_figure.m`](./matlab-plot-skill/scripts/export_publication_figure.m)
- [`matlab-plot-skill/references/render_review_checklist.md`](./matlab-plot-skill/references/render_review_checklist.md)
- [`matlab-plot-skill/references/matlab_figure_guidelines.md`](./matlab-plot-skill/references/matlab_figure_guidelines.md)
- [`matlab-plot-skill/agents/openai.yaml`](./matlab-plot-skill/agents/openai.yaml) (Codex UI metadata)
- [`install.ps1`](./install.ps1)
- [`install.sh`](./install.sh)
- [`examples/demo_publication_figure.m`](./examples/demo_publication_figure.m)
- [`examples/output/demo_publication_figure.png`](./examples/output/demo_publication_figure.png) (committed preview image)
- [`tests/test_export_publication_figure.m`](./tests/test_export_publication_figure.m) (MATLAB unit tests for the helper)
- [`evals/`](./evals/README.md) (trigger prompts and end-to-end quality checks)
- [`tools/validate_repo.py`](./tools/validate_repo.py)
- [`CHANGELOG.md`](./CHANGELOG.md), [`LICENSE`](./LICENSE), [`CITATION.cff`](./CITATION.cff)

## Prerequisites

- MATLAB R2021a or newer. The export helper uses `exportgraphics` (R2020a+) and argument validators such as `mustBeTextScalar` (R2020b+); the demo and the documented helper calls use name=value argument syntax (`WidthInches=6.5`), which requires R2021a+. On newer releases the helper also uses `fontname` (R2022a+) and figure themes (R2025a+) when they exist.
- Optional: `pdftoppm` (Poppler) or ImageMagick, so the agent can rasterize a PDF it needs to read.
- For repo validation only: `uv` (or Python 3 with `pyyaml`).

## Install

Clone the repo first (the installers run from the clone):

```bash
git clone https://github.com/hanlulong/matlab-plot-skill.git
cd matlab-plot-skill
```

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

Overwrite an existing installed copy with `--force`; see all options with `./install.sh --help`.

## Manual Install

Copy the [`matlab-plot-skill`](./matlab-plot-skill) folder into one or both of these locations:

- Codex: `~/.agents/skills/matlab-plot-skill`
- Claude Code: `~/.claude/skills/matlab-plot-skill`

If you installed this skill before 2026-05-30 (when the installers still targeted `~/.codex/skills`) or copied it there by hand, an old copy may still sit in `~/.codex/skills/matlab-plot-skill` (`$CODEX_HOME/skills` if you set `CODEX_HOME`). Codex still loads skills from that deprecated location, so the skill appears twice and the old copy can be stale. The installers warn about it but never delete it; remove it yourself:

```bash
rm -rf ~/.codex/skills/matlab-plot-skill
```

## Example Invocation

In Claude Code, invoke the skill directly with `/matlab-plot-skill`, or just describe the task; Claude loads the skill when the request matches its description:

```text
/matlab-plot-skill Refactor Plots/generate_my_figure.m into a publication-quality PDF figure for a two-column paper. Read the exported PNG, then iterate until the spacing and titles are clean.
```

```text
Clean up the MATLAB figure in make_irf_plot.m for my LaTeX paper: one shared legend, readable fonts at text width, vector PDF.
```

In Codex, mention the skill with `$matlab-plot-skill`:

```text
Use $matlab-plot-skill to refactor Plots/generate_my_figure.m into a publication-quality PDF figure. Read the exported figure and the compiled paper page, then iterate until the spacing and titles are clean.
```

```text
Use $matlab-plot-skill to improve this MATLAB appendix figure. Keep the color mapping fixed across panels, distinguish variants with markers, export a vector PDF, and read the generated figure yourself before stopping.
```

## Demo Example

Run this from the repository root (the path is relative to MATLAB's working directory):

```bash
matlab -batch "run('examples/demo_publication_figure.m')"
```

This generates:

- `examples/output/demo_publication_figure.pdf`
- `examples/output/demo_publication_figure.png`

The PNG is there for fast review. The PDF is the publication-style export for the paper workflow. Only the PNG (used as the preview above) is committed; the vector PDF is git-ignored and produced locally when you run the demo.

## Validation

`tools/validate_repo.py` is an optional local check (the repo has no CI). Run it before contributing:

```bash
uv run --with pyyaml python tools/validate_repo.py .
```

(Or `pip install -r requirements-dev.txt` first, then `python tools/validate_repo.py .`.)

This checks:

- required skill packaging files, including the committed demo PNG
- `SKILL.md` front matter against the Agent Skills rules and Codex's allowed keys, and that the body still expresses the render-review-iterate workflow
- the version in `SKILL.md` metadata matches `CITATION.cff` and has a `CHANGELOG.md` entry
- the export helper still uses `exportgraphics` vector output, and the demo still calls that helper
- relative markdown links resolve (README, CHANGELOG, SKILL.md, and the reference files)
- `openai.yaml` skill metadata
- `evals/trigger-evals.json` parses and has both should-trigger and should-not-trigger prompts
- PowerShell install flow (when PowerShell is available), including the legacy-copy warning
- bash install flow (when bash is available), including `--help` and the legacy-copy warning

With MATLAB installed, also run the helper's unit tests from the repository root:

```bash
matlab -batch "assertSuccess(runtests('tests'))"
```

## Making Changes

1. If you change the MATLAB code, lint it locally: `matlab -batch "checkcode('matlab-plot-skill/scripts/export_publication_figure.m')"` (and the demo), and run the unit tests above.
2. If you change the demo or the helper, re-run the demo with MATLAB and re-commit `examples/output/demo_publication_figure.png` (the committed preview image).
3. For a release, bump `metadata.version` in `SKILL.md` and `version` in `CITATION.cff`, and add a [`CHANGELOG.md`](./CHANGELOG.md) entry.
4. Run the validator above before committing.

## Notes

- Codex reads [`agents/openai.yaml`](./matlab-plot-skill/agents/openai.yaml) for optional UI metadata.
- Claude Code can use the same `SKILL.md`-based folder structure.
- The installer copies the skill, so re-run it with `--force` (`-Force` on PowerShell) after you update the repo to refresh the installed copy.
- Claude Code picks up new and changed skills in `~/.claude/skills` without a restart. If `~/.claude/skills` did not exist when your session started, run `/reload-skills` once. Restart Codex after installing so it loads the skill.
- See [`CHANGELOG.md`](./CHANGELOG.md) for what changed in each version. Version 0.2.0 changed the helper's defaults: it now keeps your figure size and layout spacing unless you pass `WidthInches`/`HeightInches` or `TileSpacing`/`LayoutPadding`. A script that passes only `WidthInches` to a plain `figure` now keeps MATLAB's default height (about 6 in under `matlab -batch`) instead of 4 in; the helper warns (`export_publication_figure:defaultSize`), and passing `HeightInches=4` restores the 0.1.0 output.
