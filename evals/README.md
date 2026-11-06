# Evals

## Trigger evals

[`trigger-evals.json`](./trigger-evals.json) lists realistic prompts with whether the skill should load (`should_trigger`). The should-not-trigger prompts are near-misses: other plotting tools (matplotlib, ggplot2, Stata, Excel), MATLAB work that is not plotting, and figure-adjacent writing or LaTeX tasks that belong to other skills.

The file uses the `[{"query": ..., "should_trigger": ...}]` format that the skill-creator skill's trigger-eval scripts read. Re-check it whenever you change the `description` in [`SKILL.md`](../matlab-plot-skill/SKILL.md).

## Quality checks

When you change the skill or the helper, run a few real tasks end to end and check the result against these lists.

**Messy multi-panel figure.** Prompt: "Clean up this 2x2 `subplot` figure for a one-column paper" (any script with four `subplot` panels, per-panel legends, and a figure exported with `saveas`).

- [ ] Uses `tiledlayout` with one shared legend docked to the layout.
- [ ] Measures or asks for the include width instead of assuming 3.3 in, and exports at that width.
- [ ] Runs MATLAB, reads the PNG preview, and names at least one concrete thing it fixed after looking.
- [ ] Delivers a vector PDF whose fonts are all one family (`pdffonts`).

**New figure from data.** Prompt: "Plot the impulse responses in `irf.mat` with 68% and 90% bands for my paper."

- [ ] Draws bands as shaded patches behind the lines, in the line's color.
- [ ] Passes `WidthInches` and `HeightInches` to the helper (or sets the figure size explicitly).
- [ ] Reports the PNG path it read.

**No MATLAB available.** Same prompt with MATLAB missing from `PATH`.

- [ ] Says plainly that the figure was not rendered or reviewed.
- [ ] Gives the exact `matlab -batch` command to run and what to check.
