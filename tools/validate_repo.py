from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import yaml


SKILL_DIR = "matlab-plot-skill"

# Keys accepted by both the Agent Skills spec and Codex's quick_validate.
# (`compatibility` is valid in the spec but Codex's validator rejects it.)
ALLOWED_FRONT_MATTER_KEYS = {"name", "description", "license", "metadata", "allowed-tools"}
SKILL_NAME_PATTERN = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")

REQUIRED_FILES = [
    "README.md",
    "CHANGELOG.md",
    "CITATION.cff",
    "install.ps1",
    "install.sh",
    "matlab-plot-skill/SKILL.md",
    "matlab-plot-skill/agents/openai.yaml",
    "matlab-plot-skill/references/matlab_figure_guidelines.md",
    "matlab-plot-skill/references/render_review_checklist.md",
    "matlab-plot-skill/scripts/export_publication_figure.m",
    "examples/README.md",
    "examples/demo_publication_figure.m",
    # Hero image rendered at the top of README.md (a copy of the demo's PNG;
    # the demo itself writes to the git-ignored examples/output/).
    "docs/demo_publication_figure.png",
    # MATLAB regression tests for the export helper (run when MATLAB exists).
    "tests/test_export_publication_figure.m",
    "evals/README.md",
    "evals/trigger-evals.json",
    # Dev dependency manifest referenced by the README pip path.
    "requirements-dev.txt",
    # Plugin manifests for the Claude Code and Codex plugin installs.
    ".claude-plugin/plugin.json",
    ".codex-plugin/plugin.json",
    "RELEASING.md",
]

PLUGIN_MANIFESTS = [".claude-plugin/plugin.json", ".codex-plugin/plugin.json"]


def assert_exists(repo_root: Path) -> None:
    missing = [path for path in REQUIRED_FILES if not (repo_root / path).exists()]
    if missing:
        raise SystemExit("Missing required files:\n- " + "\n- ".join(missing))


def parse_skill_front_matter(repo_root: Path) -> None:
    skill_path = repo_root / "matlab-plot-skill" / "SKILL.md"
    text = skill_path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        raise SystemExit("SKILL.md is missing YAML front matter.")

    parts = text.split("---\n", 2)
    if len(parts) < 3:
        raise SystemExit("SKILL.md front matter is malformed.")

    try:
        front_matter = yaml.safe_load(parts[1]) or {}
    except yaml.YAMLError as exc:
        # A backslash inside a double-quoted YAML string (e.g. a LaTeX macro) is
        # an invalid escape; clients would then load the skill with no metadata.
        raise SystemExit(f"SKILL.md front matter is not valid YAML: {exc}") from None
    check_front_matter_spec(front_matter)
    description = str(front_matter.get("description", "")).lower()
    # Stable single-word discoverability keywords. Multi-word phrases are
    # intentionally NOT required here so the description can be reworded freely.
    required_terms = ["matlab", "publication", "figure"]
    missing = [term for term in required_terms if term not in description]
    if missing:
        raise SystemExit(
            "SKILL.md description is missing expected discoverability terms: "
            + ", ".join(missing)
        )

    # Validate that the body still expresses the load-bearing CONCEPTS of the
    # render-review-iterate contract, using tolerant patterns rather than exact
    # sentences so that ordinary copy-editing does not falsely fail.
    body = parts[2]
    concept_checks = {
        "do-not-stop contract": r"(do not|don'?t|never)\s+stop",
        # Require a read verb NEAR a rendered-artifact noun, so the load-bearing
        # "read the rendered PNG" instruction is actually guarded (a bare
        # "rendering"/"reader" elsewhere no longer satisfies the check).
        "read / inspect the rendered output": r"(read|inspect|look at)\b[^\n]{0,40}(render|png|figure|output|pdf)",
        "iterate": r"\biterat(e|ing|ion)",
        "vector export": r"(vector|exportgraphics)",
    }
    missing_concepts = [
        label
        for label, pattern in concept_checks.items()
        if not re.search(pattern, body, re.IGNORECASE)
    ]
    if missing_concepts:
        raise SystemExit(
            "SKILL.md body no longer expresses required workflow concepts: "
            + ", ".join(missing_concepts)
        )


def check_front_matter_spec(front_matter: dict) -> None:
    # Agent Skills spec rules plus Codex quick_validate's key allow-list, so a
    # frontmatter edit cannot silently break loading in either client.
    unexpected = set(front_matter) - ALLOWED_FRONT_MATTER_KEYS
    if unexpected:
        raise SystemExit(
            "SKILL.md front matter has unsupported keys: " + ", ".join(sorted(unexpected))
        )

    name = front_matter.get("name")
    if not isinstance(name, str) or not SKILL_NAME_PATTERN.match(name):
        raise SystemExit(f"SKILL.md name must be lowercase hyphen-case, got {name!r}.")
    if len(name) > 64:
        raise SystemExit("SKILL.md name must be at most 64 characters.")
    if name != SKILL_DIR:
        raise SystemExit(f"SKILL.md name {name!r} must match its directory {SKILL_DIR!r}.")
    if "claude" in name or "anthropic" in name:
        raise SystemExit("SKILL.md name must not contain 'claude' or 'anthropic'.")

    description = front_matter.get("description")
    if not isinstance(description, str) or not description.strip():
        raise SystemExit("SKILL.md description must be a non-empty string.")
    if len(description) > 1024:
        raise SystemExit(f"SKILL.md description is {len(description)} characters; max 1024.")
    if "<" in description or ">" in description:
        raise SystemExit("SKILL.md description must not contain angle brackets.")

    metadata = front_matter.get("metadata", {})
    if not isinstance(metadata, dict):
        raise SystemExit("SKILL.md metadata must be a mapping.")
    if "version" in metadata and not isinstance(metadata["version"], str):
        raise SystemExit("SKILL.md metadata.version must be a quoted string.")


def check_versions(repo_root: Path) -> None:
    # Keep the release version in sync across SKILL.md, CITATION.cff, and the
    # CHANGELOG so a release cannot ship with mismatched numbers.
    version = skill_version(repo_root)
    citation = yaml.safe_load((repo_root / "CITATION.cff").read_text(encoding="utf-8"))
    citation_version = str(citation.get("version", ""))
    if not version or version != citation_version:
        raise SystemExit(
            f"Version mismatch: SKILL.md metadata.version={version!r}, "
            f"CITATION.cff version={citation_version!r}."
        )
    changelog = (repo_root / "CHANGELOG.md").read_text(encoding="utf-8")
    # A dated heading, so a release cannot ship an "Unreleased" entry.
    if not re.search(
        rf"^## \[{re.escape(version)}\] - \d{{4}}-\d{{2}}-\d{{2}}$", changelog, re.MULTILINE
    ):
        raise SystemExit(f"CHANGELOG.md has no dated '## [{version}] - YYYY-MM-DD' entry.")
    tag = f"{SKILL_DIR}--v{version}"
    if f"...{tag}" not in changelog:
        raise SystemExit(f"CHANGELOG.md compare link must end at the release tag {tag}.")


def skill_version(repo_root: Path) -> str:
    skill_text = (repo_root / SKILL_DIR / "SKILL.md").read_text(encoding="utf-8")
    front_matter = yaml.safe_load(skill_text.split("---\n", 2)[1]) or {}
    return str((front_matter.get("metadata") or {}).get("version", ""))


def check_plugin_manifests(repo_root: Path) -> None:
    # Both plugin manifests must name the skill, carry the release version, and
    # point at the folder that holds SKILL.md, or a plugin install would load an
    # old version or no skill at all.
    version = skill_version(repo_root)
    for manifest_path in PLUGIN_MANIFESTS:
        try:
            manifest = json.loads((repo_root / manifest_path).read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            raise SystemExit(f"{manifest_path} is not valid JSON: {exc}") from None
        if manifest.get("name") != SKILL_DIR:
            raise SystemExit(f"{manifest_path} name must be {SKILL_DIR!r}.")
        if manifest.get("version") != version:
            raise SystemExit(
                f"{manifest_path} version {manifest.get('version')!r} does not match "
                f"SKILL.md metadata.version {version!r}."
            )
        if manifest.get("license") != "MIT":
            raise SystemExit(f"{manifest_path} license must be 'MIT'.")
        skills = manifest.get("skills")
        if not isinstance(skills, str) or not skills.startswith("./"):
            raise SystemExit(f"{manifest_path} skills must be a './'-relative path.")
        if not (repo_root / skills / "SKILL.md").is_file():
            raise SystemExit(f"{manifest_path} skills path {skills!r} has no SKILL.md.")
    interface = json.loads(
        (repo_root / ".codex-plugin" / "plugin.json").read_text(encoding="utf-8")
    ).get("interface", {})
    prompts = interface.get("defaultPrompt", [])
    if not isinstance(prompts, list) or len(prompts) > 3 or any(
        not isinstance(prompt, str) or len(prompt) > 128 for prompt in prompts
    ):
        raise SystemExit(
            ".codex-plugin/plugin.json interface.defaultPrompt must be at most 3 strings "
            "of at most 128 characters."
        )


def check_trigger_evals(repo_root: Path) -> None:
    # Keep the trigger eval set loadable by skill-creator's scripts and balanced
    # between prompts that should and should not load the skill.
    items = json.loads((repo_root / "evals" / "trigger-evals.json").read_text(encoding="utf-8"))
    if not isinstance(items, list) or not all(
        isinstance(item, dict)
        and isinstance(item.get("query"), str)
        and isinstance(item.get("should_trigger"), bool)
        for item in items
    ):
        raise SystemExit('evals/trigger-evals.json must be a list of {"query", "should_trigger"}.')
    positives = sum(item["should_trigger"] for item in items)
    if positives < 3 or len(items) - positives < 2:
        raise SystemExit(
            "evals/trigger-evals.json needs at least 3 should-trigger and 2 should-not-trigger prompts."
        )


def check_matlab_artifacts(repo_root: Path) -> None:
    # MATLAB is not assumed to be installed, so guard the repo's headline
    # promise (vector export helper + demo that uses it) with static checks.
    helper = (
        repo_root / "matlab-plot-skill" / "scripts" / "export_publication_figure.m"
    ).read_text(encoding="utf-8")
    if "function export_publication_figure(" not in helper:
        raise SystemExit("Export helper function signature changed unexpectedly.")
    if "exportgraphics(" not in helper:
        raise SystemExit("Export helper no longer calls exportgraphics.")
    # Match the arguments-block default specifically, not a stray "vector" in a
    # comment, so a real default-change regression (e.g. to "image") is caught.
    if not re.search(r'ContentType[^\n=]*=\s*"vector"', helper):
        raise SystemExit("Export helper no longer defaults to vector output.")

    demo = (
        repo_root / "examples" / "demo_publication_figure.m"
    ).read_text(encoding="utf-8")
    if "export_publication_figure(" not in demo:
        raise SystemExit("Demo no longer calls the export helper.")


def check_relative_links(repo_root: Path) -> None:
    # Catch rotted relative markdown links/images (e.g. a moved hero image or a
    # renamed reference file) that would 404 on GitHub.
    docs = [
        "README.md",
        "CHANGELOG.md",
        "examples/README.md",
        "evals/README.md",
        f"{SKILL_DIR}/SKILL.md",
        "RELEASING.md",
    ]
    docs += sorted(
        str(path.relative_to(repo_root))
        for path in (repo_root / SKILL_DIR / "references").glob("*.md")
    )
    broken: list[str] = []
    link_pattern = re.compile(r"\]\((\.?/?[^)\s#]+)")
    for doc in docs:
        doc_path = repo_root / doc
        text = doc_path.read_text(encoding="utf-8")
        for target in link_pattern.findall(text):
            if target.startswith(("http://", "https://", "mailto:")):
                continue
            if not (doc_path.parent / target).resolve().exists():
                broken.append(f"{doc} -> {target}")
    if broken:
        raise SystemExit("Broken relative links:\n- " + "\n- ".join(broken))


def parse_openai_yaml(repo_root: Path) -> None:
    config_path = repo_root / "matlab-plot-skill" / "agents" / "openai.yaml"
    config = yaml.safe_load(config_path.read_text(encoding="utf-8")) or {}
    interface = config.get("interface", {})
    prompt = str(interface.get("default_prompt", ""))
    if "$matlab-plot-skill" not in prompt:
        raise SystemExit("openai.yaml default_prompt must mention $matlab-plot-skill.")


def installer_env(tmp_path: Path) -> dict[str, str]:
    # Point CODEX_HOME at the temp dir so the legacy-copy check never reads the
    # developer's real ~/.codex.
    env = dict(os.environ)
    env["CODEX_HOME"] = str(tmp_path / "codex-home")
    return env


def check_legacy_warning(command: list[str], repo_root: Path, tmp_path: Path, label: str) -> None:
    # With no legacy copy there must be no warning; with one, the installer must
    # warn and leave it in place (it never deletes it).
    quiet = subprocess.run(
        command, cwd=repo_root, env=installer_env(tmp_path), capture_output=True, text=True
    )
    if quiet.returncode != 0 or "older copy" in quiet.stdout + quiet.stderr:
        raise SystemExit(f"{label} installer warned about a legacy copy that does not exist.")

    legacy = tmp_path / "codex-home" / "skills" / "matlab-plot-skill"
    legacy.mkdir(parents=True)
    warned = subprocess.run(
        command, cwd=repo_root, env=installer_env(tmp_path), capture_output=True, text=True
    )
    if warned.returncode != 0 or "older copy" not in warned.stdout + warned.stderr:
        raise SystemExit(f"{label} installer did not warn about the legacy Codex copy.")
    if not legacy.exists():
        raise SystemExit(f"{label} installer deleted the legacy Codex copy.")
    legacy.rmdir()


def run_powershell_install(repo_root: Path) -> None:
    if shutil.which("pwsh") is None and shutil.which("powershell") is None:
        print("Skipping PowerShell installer test: PowerShell not found.")
        return

    shell = shutil.which("pwsh") or shutil.which("powershell")
    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        codex_path = tmp_path / "codex-skills"
        claude_path = tmp_path / "claude-skills"
        command = [
            shell,
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(repo_root / "install.ps1"),
            "-Target",
            "both",
            "-CodexSkillsPath",
            str(codex_path),
            "-ClaudeSkillsPath",
            str(claude_path),
            "-Force",
        ]
        subprocess.run(command, check=True, cwd=repo_root, env=installer_env(tmp_path))
        for path in [codex_path, claude_path]:
            installed = path / "matlab-plot-skill" / "SKILL.md"
            if not installed.exists():
                raise SystemExit(f"PowerShell installer did not create {installed}")

        check_legacy_warning(command, repo_root, tmp_path, "PowerShell")

        # Re-running without -Force must refuse to clobber an existing install.
        rerun = subprocess.run(
            command[:-1], cwd=repo_root, env=installer_env(tmp_path), capture_output=True
        )
        if rerun.returncode == 0:
            raise SystemExit(
                "PowerShell installer overwrote an existing install without -Force."
            )


def run_bash_install(repo_root: Path) -> None:
    bash = shutil.which("bash")
    if bash is None:
        candidate_paths = [
            Path(r"C:\Program Files\Git\bin\bash.exe"),
            Path(r"C:\Program Files\Git\usr\bin\bash.exe"),
        ]
        for candidate in candidate_paths:
            if candidate.exists():
                bash = str(candidate)
                break
    if bash is None:
        print("Skipping bash installer test: bash not found.")
        return

    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        codex_path = tmp_path / "codex-skills"
        claude_path = tmp_path / "claude-skills"
        command = [
            bash,
            str(repo_root / "install.sh"),
            "--target",
            "both",
            "--codex-path",
            str(codex_path),
            "--claude-path",
            str(claude_path),
            "--force",
        ]
        subprocess.run(command, check=True, cwd=repo_root, env=installer_env(tmp_path))
        for path in [codex_path, claude_path]:
            installed = path / "matlab-plot-skill" / "SKILL.md"
            if not installed.exists():
                raise SystemExit(f"Bash installer did not create {installed}")

        check_legacy_warning(command, repo_root, tmp_path, "Bash")

        help_run = subprocess.run(
            [bash, str(repo_root / "install.sh"), "--help"],
            cwd=repo_root,
            capture_output=True,
            text=True,
        )
        if help_run.returncode != 0 or "Usage:" not in help_run.stdout:
            raise SystemExit("Bash installer --help must print usage and exit 0.")

        # Re-running without --force must refuse to clobber an existing install.
        rerun = subprocess.run(
            command[:-1], cwd=repo_root, env=installer_env(tmp_path), capture_output=True
        )
        if rerun.returncode == 0:
            raise SystemExit(
                "Bash installer overwrote an existing install without --force."
            )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("repo_root", nargs="?", default=".")
    args = parser.parse_args()

    repo_root = Path(args.repo_root).resolve()
    assert_exists(repo_root)
    parse_skill_front_matter(repo_root)
    check_versions(repo_root)
    check_plugin_manifests(repo_root)
    check_trigger_evals(repo_root)
    check_matlab_artifacts(repo_root)
    check_relative_links(repo_root)
    parse_openai_yaml(repo_root)
    run_powershell_install(repo_root)
    run_bash_install(repo_root)
    print("Repository validation passed.")


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as exc:
        sys.exit(exc.returncode)
