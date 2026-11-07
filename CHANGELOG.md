# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [0.2.2] - 2026-11-07

Documentation and comment fixes only; the export helper's executable code is unchanged.

### Fixed

- **Default colors.** The guidelines gave MATLAB's default blue and orange only as the pre-R2025a values. They now also give the R2025a+ `"gem"` values (`[0.066 0.443 0.745]` / `[0.866 0.329 0]`), as listed in the `colororder` Version History.
- **Renderer.** The guidelines said `set(gcf, 'Renderer', ...)` still affects on-screen drawing and the legacy `print`/`saveas` paths. MathWorks says that from R2025a the figure `Renderer` and `RendererMode` properties have no effect. The guidelines and a helper comment now say so.
- The helper Notes say the line-width floor reaches every line in Cartesian axes (it does not reach lines in `polaraxes` or `geoaxes`), and name the warning a raster output path prints on R2026a with the default `ContentType="vector"`: `MATLAB:print:ImageOutputIgnoresVectorContentType`.

## [0.2.1] - 2026-11-07

The export helper's executable code is unchanged (comments only). Every other change is to the documentation, the eval data, or a GitHub issue form.

### Fixed

- **Minus signs.** The guidance said MATLAB writes negative tick labels with the Unicode minus (U+2212). On R2026a it writes the ASCII hyphen-minus (U+002D). The guidelines and the checklist now say so, and say to relabel the ticks deliberately when a journal requires a true minus.
- **Tick label formats.** `TickLabelFormat` formats the values shown next to the x10^n multiplier, not the raw values, so `'%,.0f'` on a 0-250,000 axis printed 0 | 1 | 1 | 2 | 2 | 3 (seen on R2026a). The guidelines now say to set `ax.YAxis.Exponent = 0` first for a format written for the raw values.
- **Color order.** The Okabe-Ito example used `set(groot, 'defaultAxesColorOrder', ...)`, which changes every later figure in the MATLAB session. It now uses `colororder(fig, okabeIto)`, and says that a per-axes order is replaced by the next plotting call unless `hold(ax, 'on')` comes first.
- The Worked Recipe plotted into the current axes (`nexttile; plot(x, y1)`). It now passes the handle from `nexttile(tl)` to `plot` and `title`, as the demo does.
- SKILL.md names the Codex plugin cache as `$CODEX_HOME/plugins/cache/` (default `~/.codex/plugins/cache/`), so a custom `CODEX_HOME` is covered.
- Two pieces of export advice the helper could not follow. "Export the `tiledlayout` or `axes` handle directly" now says to call `exportgraphics` on it, because the helper accepts only a figure. "Export the whole figure as an image at 300-600 DPI" now says to run the helper and then call `exportgraphics` with `'Resolution'`, because the helper exports images at the default 150 dpi.

### Added

- **Helper Notes.** The help text of `export_publication_figure.m` now says what the helper forces: every Cartesian axes gets `Box='off'`, `TickDir='out'` and `LineWidth=0.8`, and every legend gets `Box='off'`, which also removes its white background. It also says that the font size and weight options reach only Cartesian axes (not `polaraxes`, `geoaxes` or `heatmap`), that the `SuperTitle*` options do not reach `sgtitle`, that the figure is left with `Units='inches'`, that only a figure handle is accepted, that the line-width floor also reaches lines with `HandleVisibility='off'`, and that image exports (a raster output path or `ContentType="image"`) use the default 150 dpi. SKILL.md's Helper section points to these Notes.
- Export notes in the guidelines: EPS writes a `FaceAlpha` band as an opaque fill, so prefer PDF; and a figure whose axes sit in two or more `uipanel`s or tabs fails to export as a whole (seen on R2026a), so export each container with `exportgraphics` or rebuild the panels as one `tiledlayout`.
- **Uncertainty bands.** A band drawn as one `fill` or `patch` polygon disappears without an error if any bound is NaN, so the guidelines say to draw one band per run of finite bounds and keep the NaN gap in the mean line. They also say to keep bands out of the legend (no `data1` entries). The checklist and the end-to-end quality checks have matching items.
- **Honest Encoding checks** in the review checklist: interval labels, one color scale for compared panels (`CLim` for axes plots, `ColorLimits` for `heatmap` charts), gaps for missing values, bars from zero, and `yyaxis` only for different units. The agent reports these to the user instead of changing the data, chart type, or caption.
- A grayscale preview command in the checklist (`pdftoppm -gray`, or `im2gray` in the same `matlab -batch` call), and a note that Chinese, Japanese or Korean labels add a system fallback font to the PDF, which is expected.
- README install notes: uploading the release zip on claude.ai, where the skill writes the code and the `matlab -batch` command for you to run, and a one-time `-ExecutionPolicy Bypass` when PowerShell blocks `install.ps1`.
- Four trigger prompts (20 in all, 10 of each kind): an `export_fig` export and a MATLAB `heatmap` should load the skill; App Designer data tips and an `animatedline` animation should not.
- A "Report a bad figure" issue form.

Ideas adapted, no text copied: K-Dense-AI/scientific-agent-skills, Haojae/scipilot-figure-skill and blader/humanizer (all MIT).

## [0.2.0] - 2026-11-07

### Changed

- **Export helper keeps the caller's figure size and layout spacing.** `WidthInches` and `HeightInches` now default to `[]` (keep the current size) instead of forcing 6.5 x 4 in, and only the dimensions you pass are changed. `LayoutPadding` and `TileSpacing` now default to `""` (keep each `tiledlayout`'s own setting) instead of forcing `"compact"`. To get the old size and spacing, pass `WidthInches=6.5, HeightInches=4, LayoutPadding="compact", TileSpacing="compact", SuperTitleFontSize=12, SuperTitleFontWeight="normal"` (on R2025a+ the PDF is now exactly that size rather than a tight crop, and shared tiledlayout labels use `AxisFontSize`). **Width-only callers:** a 0.1.0-style call such as `fig = figure; ... export_publication_figure(fig, path, WidthInches=6.5)` now keeps MATLAB's default height instead of 4 in (about 6 in under `matlab -batch` on R2026a/macOS; it varies by platform and release, and the warning prints the actual size); pass `HeightInches=4` to get the old size. The helper warns (`export_publication_figure:defaultSize`, naming the omitted dimension) whenever `WidthInches` or `HeightInches` is omitted and the figure still has MATLAB's default size.
- **Exports are the size you asked for (R2025a+).** The helper now passes the figure size to `exportgraphics` (`Width`/`Height`/`Units`), so the PDF page and the PNG preview are exactly `WidthInches` x `HeightInches` (or the figure's own size), and text in a figure built at that size prints within about 1% of its point size at that include width (a re-export of a resized figure can still be 1-3% off). Before, the export was cropped to its content, about 5-15% smaller than the figure, so `width=\linewidth` scaled the text up by the same amount; and on R2026a a figure resized after it was drawn (paper size, then slide size) could export at its previous size. PNG previews are larger to match (a 6.5 in figure at the default 220 dpi is 1430 px wide). Installed MATLAB R2021a-R2024b keeps the cropped export, since those options do not exist there.
- **The layout (super) title keeps its own size and weight** unless you pass `SuperTitleFontSize` or the new `SuperTitleFontWeight`. `SuperTitleFontSize` now defaults to `[]`.
- The skill description is rewritten in the third person and now covers new figures, `exportgraphics`/`print`/`saveas`, `tiledlayout`/`subplot`, and Beamer slides, with a not-for boundary (matplotlib, R, Stata, Excel). The Codex UI short description (`agents/openai.yaml`) now covers creating figures too.
- Installers no longer tell you to restart Claude Code: it picks up new skills automatically (run `/reload-skills` if `~/.claude/skills` was just created). For Codex they now say that it detects new skills automatically and to restart it only if the skill does not appear, matching the Codex documentation.
- The demo exports at its final 6.5 x 5 in size, maps one color to one concept in every panel, uses one shared legend and panel letters A-C, and sets spacing once. The README hero image is regenerated with the new helper and moved to `docs/demo_publication_figure.png`.
- **The demo writes to the git-ignored `examples/output/`**, so running it no longer modifies a tracked file (which made a later `git pull` abort). The README explains how to recover an older clone.
- The recommended Okabe-Ito line order puts the five colors with at least 3:1 contrast against white first and leaves yellow (1.3:1) out of the line order; the values are now the palette's exact RGB triplets.
- SKILL.md tells the agent to run a script by name from the project root (`addpath('Plots'); make_figure`) instead of `run('Plots/make_figure.m')`, which changes folder and breaks project-relative paths such as `load('data/irf.mat')`.
- SKILL.md tells the agent to copy the helper into the project next to the plotting script, and never to write the skill's install path into the user's `.m` file: plugin installs live in a version-numbered folder that is replaced on update, and coauthors or a replication package do not have it. A one-off render may put the skill's `scripts` folder on the path in the `matlab -batch` command instead. Step 3 now says that `exportgraphics` `Width`/`Height` should equal the figure's own size.
- The Codex display name (`.codex-plugin/plugin.json` and `agents/openai.yaml`) is now "MATLAB Plot", the name the OpenEconAI catalog lists.

### Added

- **Plugin packaging.** `.claude-plugin/plugin.json` and `.codex-plugin/plugin.json` (plugin name `matlab-plot-skill`, the same as the skill), so the skill can be installed from the OpenEconAI/plugins catalog: `/plugin install matlab-plot-skill@openeconai` in Claude Code, `codex plugin add matlab-plot-skill@openeconai` in Codex. The skill stays in `matlab-plot-skill/`. Releases are now tagged `matlab-plot-skill--vX.Y.Z`, the catalog's form; `RELEASING.md` lists the steps.
- README sections on updating and uninstalling for plugin and clone installs, including when changes take effect (`/reload-plugins` or a new session in Claude Code, a new session in Codex).
- A paste-to-agent install prompt in the README, which the OpenEconAI catalog copies verbatim.
- MATLAB-not-found guidance: the README shows how to put `matlab` on `PATH` on macOS, and SKILL.md tells the agent to look in the usual install folders before concluding MATLAB is missing.
- Codex sandbox guidance: MATLAB cannot start inside Codex's macOS sandbox (on Apple Silicon it exits with "Incompatible processor ... neon"), so SKILL.md tells the agent to request escalated permissions for the `matlab` command.
- The helper sets one font on every text object (`fontname`, R2022a+, with a `findall` fallback), so `text()` annotations and `xline`/`yline` labels no longer leave a second font in the PDF.
- The helper switches R2025a+ figures to the light theme before export, so a dark-theme session no longer exports gray text on a black plot box.
- `tests/test_export_publication_figure.m`: MATLAB unit tests for size, exported page size, spacing, super title, fonts, and the dark theme.
- `evals/`: 16 trigger prompts (8 should-trigger, 8 near-miss should-not-trigger) in skill-creator's format, plus end-to-end quality checklists.
- Installers warn when an older copy is still installed in Codex's deprecated `~/.codex/skills` (or `$CODEX_HOME/skills`), which Codex loads as a duplicate, and print the removal command (for a symlink or junction, `install.ps1` prints a command that removes only the link). They never delete it.
- `install.sh --help`; comment-based help for `install.ps1` (`Get-Help .\install.ps1`).
- SKILL.md frontmatter: `license: MIT` and `metadata.version`.
- `tools/validate_repo.py` checks the frontmatter against the Agent Skills rules and Codex's key allow-list, keeps the SKILL.md, plugin manifest, CITATION.cff, and CHANGELOG versions in sync (with a dated heading and a compare link to the release tag), checks links in the reference files, and tests the installers' `--help` and legacy-copy warning.
- A table of contents for `references/matlab_figure_guidelines.md`, and a table of measured `\textwidth`/`\columnwidth` values for common LaTeX classes and Beamer.

### Fixed

- The guidance recommended `viridis` and `cividis`, which are not built into MATLAB (`colormap(viridis)` errors). It now recommends `parula` or `sky` (R2023a+), with `turbo` only when many distinct hues are needed.
- Step 1 treated `\columnwidth` as a 3.3 in single column. In one-column documents it equals `\textwidth`; only two-column classes are about 3.2-3.5 in. The guidance now says to measure with `\the\linewidth`.
- The rasterization advice said one panel could be raster while the rest stayed vector. `ContentType='image'` rasterizes the whole export, text included; the guidance now lists the real options.
- `TitleFontWeight` is validated case-insensitively (`"Bold"` used to be rejected), and an invalid value's error names the parameter.
- The tiledlayout's shared X/Y labels now use `AxisFontSize` instead of staying larger than the axes text.
- `install.ps1` stops on the first error (it could print "Installed" after a failed copy) and removes only the link when the destination is a symlink or junction.
- **The installers no longer delete the clone they run from.** When the clone was made inside a skills folder (for example `~/.claude/skills/matlab-plot-skill`) or a skills path pointed at the repo root, `--force` (`-Force`) removed the destination, and with it the clone, `.git` and local edits included, before the copy failed. This dates from 0.1.0. Both installers now refuse such a destination and check every destination before copying anything. The Bash installer compares folders by identity rather than spelling, so a clone in a folder whose name differs only in case or Unicode normalization (macOS file systems ignore both by default) is caught too.
- `install.ps1` compares physical paths when it looks for a legacy `~/.codex/skills` copy, so when `~/.codex/skills` is a link to `~/.agents/skills` it no longer reports the copy it just installed as an older one, with a removal command that would have deleted it.
- The helper styles the labels on both sides of `yyaxis` axes (the inactive side kept MATLAB's larger default label size) and the z-axis label.
- A string output path without a folder (`"s.pdf"`) no longer prints MATLAB's "An empty directory name was given" warning on every export. This dates from 0.1.0.
- The guidance says that text with `Interpreter='latex'` always exports in Computer Modern, so a one-family `pdffonts` check does not lead the agent to strip LaTeX math labels.
- Version requirements now say R2021a+ everywhere (the helper's `mustBeTextScalar` needs R2020b, and the name=value call syntax needs R2021a).
- The Worked Recipe passes `HeightInches`, and the `<skill>` path placeholder is replaced by `${CLAUDE_SKILL_DIR}` with a Codex fallback.

## [0.1.0] - 2026-05-30

### Added

- `matlab-plot-skill` for Codex and Claude Code: a render-review-iterate workflow for publication-quality MATLAB figures, the `export_publication_figure.m` helper (vector PDF plus PNG preview), figure guidelines, and a render review checklist.
- Installers for macOS/Linux (`install.sh`) and Windows (`install.ps1`), targeting `~/.agents/skills` for Codex and `~/.claude/skills` for Claude Code.
- A runnable demo with a committed preview image, and `tools/validate_repo.py`.

[0.2.2]: https://github.com/hanlulong/matlab-plot-skill/compare/matlab-plot-skill--v0.2.1...matlab-plot-skill--v0.2.2
[0.2.1]: https://github.com/hanlulong/matlab-plot-skill/compare/matlab-plot-skill--v0.2.0...matlab-plot-skill--v0.2.1
[0.2.0]: https://github.com/hanlulong/matlab-plot-skill/compare/v0.1.0...matlab-plot-skill--v0.2.0
[0.1.0]: https://github.com/hanlulong/matlab-plot-skill/releases/tag/v0.1.0
