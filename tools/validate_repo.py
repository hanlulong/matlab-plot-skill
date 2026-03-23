from __future__ import annotations

import argparse
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
]


def assert_exists(repo_root: Path) -> None:
    missing = [path for path in REQUIRED_FILES if not (repo_root / path).exists()]
    if missing:
        raise SystemExit(f"Missing required files:\n- " + "\n- ".join(missing))


def parse_skill_front_matter(repo_root: Path) -> None:
    skill_path = repo_root / "matlab-plot-skill" / "SKILL.md"
    text = skill_path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        raise SystemExit("SKILL.md is missing YAML front matter.")

    parts = text.split("---\n", 2)
    if len(parts) < 3:
        raise SystemExit("SKILL.md front matter is malformed.")

    front_matter = yaml.safe_load(parts[1]) or {}
    description = str(front_matter.get("description", ""))
    lowered = description.lower()
    required_terms = [
        "matlab",
        "publication",
        "figure",
        "rendered figure",
        "iterate",
    ]
    missing = [term for term in required_terms if term not in lowered]
    if missing:
        raise SystemExit(
            "SKILL.md description is missing expected discoverability terms: "
            + ", ".join(missing)
        )

    body = parts[2].lower()
    body_terms = [
        "do not stop after writing plotting code",
        "read the generated figure yourself",
        "iterate",
        "vector pdf",
    ]
    missing_body = [term for term in body_terms if term not in body]
    if missing_body:
        raise SystemExit(
            "SKILL.md body is missing required workflow phrases: "
            + ", ".join(missing_body)
        )


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


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("repo_root", nargs="?", default=".")
    args = parser.parse_args()

    repo_root = Path(args.repo_root).resolve()
    assert_exists(repo_root)
    parse_skill_front_matter(repo_root)
    parse_openai_yaml(repo_root)
    run_powershell_install(repo_root)
    run_bash_install(repo_root)
    print("Repository validation passed.")


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as exc:
        sys.exit(exc.returncode)
