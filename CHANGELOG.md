# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [0.2.0] - 2026-11-06

### Changed

- **Export helper keeps the caller's figure size and layout spacing.** `WidthInches` and `HeightInches` now default to `[]` (keep the current size) instead of forcing 6.5 x 4 in, and only the dimensions you pass are changed. `LayoutPadding` and `TileSpacing` now default to `""` (keep each `tiledlayout`'s own setting) instead of forcing `"compact"`. To get the old output, pass `WidthInches=6.5, HeightInches=4, LayoutPadding="compact", TileSpacing="compact", SuperTitleFontSize=12, SuperTitleFontWeight="normal"`. **Width-only callers:** a 0.1.0-style call such as `fig = figure; ... export_publication_figure(fig, path, WidthInches=6.5)` now keeps MATLAB's default height (about 6 in under `matlab -batch`) instead of 4 in; pass `HeightInches=4` to get the old output. The helper warns (`export_publication_figure:defaultSize`, naming the omitted dimension) whenever `WidthInches` or `HeightInches` is omitted and the figure still has MATLAB's default size.
- **The layout (super) title keeps its own size and weight** unless you pass `SuperTitleFontSize` or the new `SuperTitleFontWeight`. `SuperTitleFontSize` now defaults to `[]`.
- The skill description is rewritten in the third person and now covers new figures, `exportgraphics`/`print`/`saveas`, `tiledlayout`/`subplot`, and Beamer slides, with a not-for boundary (matplotlib, R, Stata, Excel). The Codex UI short description (`agents/openai.yaml`) now covers creating figures too.
- Installers no longer tell you to restart Claude Code: it picks up new skills automatically (run `/reload-skills` if `~/.claude/skills` was just created). Codex still needs a restart.
- The demo exports at its final 6.5 x 5 in size, maps one color to one concept in every panel, uses one shared legend and panel letters A-C, and sets spacing once. The README hero image is regenerated with the new helper.

### Added

- The helper sets one font on every text object (`fontname`, R2022a+, with a `findall` fallback), so `text()` annotations and `xline`/`yline` labels no longer leave a second font in the PDF.
- The helper switches R2025a+ figures to the light theme before export, so a dark-theme session no longer exports gray text on a black plot box.
- `tests/test_export_publication_figure.m`: MATLAB unit tests for size, spacing, super title, fonts, and the dark theme.
- `evals/`: 16 trigger prompts (8 should-trigger, 8 near-miss should-not-trigger) in skill-creator's format, plus end-to-end quality checklists.
- Installers warn when an older copy is still installed in Codex's deprecated `~/.codex/skills` (or `$CODEX_HOME/skills`), which Codex loads as a duplicate, and print the removal command (for a symlink or junction, `install.ps1` prints a command that removes only the link). They never delete it.
- `install.sh --help`; comment-based help for `install.ps1` (`Get-Help .\install.ps1`).
- SKILL.md frontmatter: `license: MIT` and `metadata.version`.
- `tools/validate_repo.py` checks the frontmatter against the Agent Skills rules and Codex's key allow-list, keeps the SKILL.md, CITATION.cff, and CHANGELOG versions in sync, checks links in the reference files, and tests the installers' `--help` and legacy-copy warning.
- A table of contents for `references/matlab_figure_guidelines.md`, and a table of measured `\textwidth`/`\columnwidth` values for common LaTeX classes and Beamer.

### Fixed

- The guidance recommended `viridis` and `cividis`, which are not built into MATLAB (`colormap(viridis)` errors). It now recommends `parula` or `sky` (R2023a+), with `turbo` only when many distinct hues are needed.
- Step 1 treated `\columnwidth` as a 3.3 in single column. In one-column documents it equals `\textwidth`; only two-column classes are about 3.2-3.5 in. The guidance now says to measure with `\the\linewidth`.
- The rasterization advice said one panel could be raster while the rest stayed vector. `ContentType='image'` rasterizes the whole export, text included; the guidance now lists the real options.
- `TitleFontWeight` is validated case-insensitively (`"Bold"` used to be rejected), and an invalid value's error names the parameter.
- The tiledlayout's shared X/Y labels now use `AxisFontSize` instead of staying larger than the axes text.
- `install.ps1` stops on the first error (it could print "Installed" after a failed copy) and removes only the link when the destination is a symlink or junction.
- Version requirements now say R2021a+ everywhere (the helper's `mustBeTextScalar` needs R2020b, and the name=value call syntax needs R2021a).
- The Worked Recipe passes `HeightInches`, and the `<skill>` path placeholder is replaced by `${CLAUDE_SKILL_DIR}` with a Codex fallback.

## [0.1.0] - 2026-05-30

### Added

- `matlab-plot-skill` for Codex and Claude Code: a render-review-iterate workflow for publication-quality MATLAB figures, the `export_publication_figure.m` helper (vector PDF plus PNG preview), figure guidelines, and a render review checklist.
- Installers for macOS/Linux (`install.sh`) and Windows (`install.ps1`), targeting `~/.agents/skills` for Codex and `~/.claude/skills` for Claude Code.
- A runnable demo with a committed preview image, and `tools/validate_repo.py`.

[0.2.0]: https://github.com/hanlulong/matlab-plot-skill/compare/v0.1.0...matlab-plot-skill--v0.2.0
[0.1.0]: https://github.com/hanlulong/matlab-plot-skill/releases/tag/v0.1.0
