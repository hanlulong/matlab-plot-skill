from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import yaml


REQUIRED_FILES = [
    "README.md",
    "install.ps1",
    "install.sh",
    "matlab-plot-skill/SKILL.md",
    "matlab-plot-skill/agents/openai.yaml",
    "matlab-plot-skill/references/matlab_figure_guidelines.md",
    "matlab-plot-skill/references/render_review_checklist.md",
    "matlab-plot-skill/scripts/export_publication_figure.m",
    "examples/README.md",
    "examples/demo_publication_figure.m",
    # Committed hero image rendered at the top of README.md.
    "examples/output/demo_publication_figure.png",
    # Dev dependency manifest referenced by the README pip path.
    "requirements-dev.txt",
]


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

    front_matter = yaml.safe_load(parts[1]) or {}
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
    docs = ["README.md", "examples/README.md", "matlab-plot-skill/SKILL.md"]
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
        subprocess.run(command, check=True, cwd=repo_root)
        for path in [codex_path, claude_path]:
            installed = path / "matlab-plot-skill" / "SKILL.md"
            if not installed.exists():
                raise SystemExit(f"PowerShell installer did not create {installed}")

        # Re-running without -Force must refuse to clobber an existing install.
        rerun = subprocess.run(command[:-1], cwd=repo_root)
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
        subprocess.run(command, check=True, cwd=repo_root)
        for path in [codex_path, claude_path]:
            installed = path / "matlab-plot-skill" / "SKILL.md"
            if not installed.exists():
                raise SystemExit(f"Bash installer did not create {installed}")

        # Re-running without --force must refuse to clobber an existing install.
        rerun = subprocess.run(command[:-1], cwd=repo_root)
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
