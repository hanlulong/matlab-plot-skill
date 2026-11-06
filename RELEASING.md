# Releasing matlab-plot-skill

Each release is a version `X.Y.Z` and an annotated tag `matlab-plot-skill--vX.Y.Z`. The OpenEconAI/plugins catalog requires the `<plugin>--vX.Y.Z` form. Releases up to 0.1.0 used plain `vX.Y.Z` tags, which stay as they are.

## 1. Prepare the release branch

1. Set the same version in all four places:
   - `metadata.version` in [`matlab-plot-skill/SKILL.md`](./matlab-plot-skill/SKILL.md)
   - `"version"` in [`.claude-plugin/plugin.json`](./.claude-plugin/plugin.json) and [`.codex-plugin/plugin.json`](./.codex-plugin/plugin.json). Claude Code keeps plugin users on this version until it changes, and Codex caches plugin installs by version, so bump it in every release.
   - `version` in [`CITATION.cff`](./CITATION.cff), with `date-released` set to the release date
2. Add a `## [X.Y.Z] - YYYY-MM-DD` section to [`CHANGELOG.md`](./CHANGELOG.md), dated with the release date, and point the compare link at the new tag (`compare/<previous tag>...matlab-plot-skill--vX.Y.Z`).
3. If the demo or the helper changed, re-run the demo, read the PNG, and copy it to `docs/` (see the README's "Making Changes").

`tools/validate_repo.py` fails if the four versions disagree, if the changelog heading is undated, or if the compare link does not end at the new tag.

## 2. Verify

Run the checks with a temporary `HOME` and client config, so no real installation is touched:

```bash
TMP="$(mktemp -d)"
mkdir -p "$TMP/h" "$TMP/t" "$TMP/c"
HOME="$TMP/h" TMPDIR="$TMP/t" uv run --with pyyaml python tools/validate_repo.py .
CLAUDE_CONFIG_DIR="$TMP/c" claude plugin validate --strict .
matlab -batch "assertSuccess(runtests('tests'))"
```

## 3. Publish

1. Push the branch, open a pull request, and merge it.
2. If the release date moved, update the `CHANGELOG.md` heading and `CITATION.cff` first.
3. Tag the merge commit and push the tag:

   ```bash
   git tag -a matlab-plot-skill--vX.Y.Z -m "matlab-plot-skill X.Y.Z" <commit>
   git push origin matlab-plot-skill--vX.Y.Z
   ```

4. Build the claude.ai upload zip and create the GitHub Release, using the changelog section as notes. On claude.ai the skill cannot run the MATLAB on your computer, so there it writes the code and gives you the exact `matlab -batch` command to run yourself; say so in the release notes, and point people to Claude Code or Codex for the render-review loop.

   ```bash
   git archive --format=zip --prefix=matlab-plot-skill/ \
     matlab-plot-skill--vX.Y.Z:matlab-plot-skill -o matlab-plot-skill-X.Y.Z.zip
   gh release create matlab-plot-skill--vX.Y.Z matlab-plot-skill-X.Y.Z.zip \
     --title "matlab-plot-skill X.Y.Z" --notes-file <notes.md> --verify-tag
   ```

5. Bump the `matlab-plot-skill` ref to `matlab-plot-skill--vX.Y.Z` in both marketplace files of OpenEconAI/plugins (`.claude-plugin/marketplace.json` and `.agents/plugins/marketplace.json`). Keep the catalog copies in sync, since its release tests compare them with this repo: the description (from the plugin manifests), the `displayName` (`interface.displayName` in [`.codex-plugin/plugin.json`](./.codex-plugin/plugin.json)), and the README's paste-to-agent prompt, which the catalog README copies verbatim under `### MATLAB Plot` and checks against this repo's default-branch README.

The README's plugin install lines work only once the catalog lists the plugin. For a first listing, push the tag before the catalog pull request and merge the release into `main` right before the catalog pull request, so neither side points at something missing for long.
