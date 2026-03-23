#!/usr/bin/env bash
set -euo pipefail

target="both"
force="false"
codex_skills_path="${HOME}/.codex/skills"
claude_skills_path="${HOME}/.claude/skills"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      target="$2"
      shift 2
      ;;
    --force)
      force="true"
      shift
      ;;
    --codex-path)
      codex_skills_path="$2"
      shift 2
      ;;
    --claude-path)
      claude_skills_path="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_source="${repo_root}/matlab-plot-skill"

if [[ ! -d "${skill_source}" ]]; then
  echo "Skill source not found: ${skill_source}" >&2
  exit 1
fi

install_skill() {
  local destination_root="$1"
  local destination="${destination_root}/matlab-plot-skill"

  mkdir -p "${destination_root}"

  if [[ -e "${destination}" ]]; then
    if [[ "${force}" != "true" ]]; then
      echo "Destination already exists: ${destination}. Re-run with --force to replace it." >&2
      exit 1
    fi

    rm -rf "${destination}"
  fi

  cp -R "${skill_source}" "${destination}"
  echo "Installed matlab-plot-skill to ${destination}"
}

case "${target}" in
  codex)
    install_skill "${codex_skills_path}"
    ;;
  claude)
    install_skill "${claude_skills_path}"
    ;;
  both)
    install_skill "${codex_skills_path}"
    install_skill "${claude_skills_path}"
    ;;
  *)
    echo "Invalid target: ${target}. Expected codex, claude, or both." >&2
    exit 1
    ;;
esac
