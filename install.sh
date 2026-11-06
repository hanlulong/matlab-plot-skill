#!/usr/bin/env bash
set -euo pipefail

target="both"
force="false"
codex_skills_path="${HOME}/.agents/skills"
claude_skills_path="${HOME}/.claude/skills"

usage() {
  cat <<EOF
Usage: ./install.sh [--target codex|claude|both] [--force]
                    [--codex-path DIR] [--claude-path DIR]

Copy the matlab-plot-skill folder into the Codex and/or Claude Code skill
directories.

Options:
  --target codex|claude|both  Where to install (default: both).
  --force                     Replace an existing installed copy.
  --codex-path DIR            Codex skills directory (default: ~/.agents/skills).
  --claude-path DIR           Claude Code skills directory (default: ~/.claude/skills).
  -h, --help                  Show this help and exit.
EOF
}

require_value() {
  # $1 is the flag name; the caller passes "$@" so $# reflects remaining args.
  if [[ $# -lt 2 ]]; then
    echo "Missing value for $1" >&2
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --target)
      require_value "$@"
      target="$2"
      shift 2
      ;;
    --force)
      force="true"
      shift
      ;;
    --codex-path)
      require_value "$@"
      codex_skills_path="$2"
      shift 2
      ;;
    --claude-path)
      require_value "$@"
      claude_skills_path="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
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

check_destination() {
  local destination_root="$1"
  local destination="${destination_root}/matlab-plot-skill"

  mkdir -p "${destination_root}"

  # Refuse when the destination is this clone or holds it (for example a clone
  # made directly in ~/.claude/skills/matlab-plot-skill, or --codex-path set to
  # the repo root): replacing it would delete the clone, .git and local edits
  # included. Compare physical paths so symlinked folders are caught too. A
  # destination that is itself a symlink is not followed: --force removes only
  # the link.
  local destination_real repo_real
  destination_real="$(cd "${destination_root}" && pwd -P)/matlab-plot-skill"
  repo_real="$(cd "${repo_root}" && pwd -P)"
  if [[ ! -L "${destination}" ]]; then
    case "${repo_real}/" in
      "${destination_real}/"*)
        echo "Refusing to install into ${destination}: that folder holds this clone (${repo_real}), and replacing it would delete the clone." >&2
        echo "Clone the repo outside your skills folders (for example ~/src/matlab-plot-skill) and run the installer from there." >&2
        exit 1
        ;;
    esac
    case "${destination_real}/" in
      "${repo_real}/matlab-plot-skill/"*)
        echo "Refusing to install into ${destination}: that is this clone's own skill folder (${repo_real}/matlab-plot-skill) or a folder inside it." >&2
        echo "Pick a skills directory outside the clone." >&2
        exit 1
        ;;
    esac
  fi
}

install_skill() {
  local destination_root="$1"
  local destination="${destination_root}/matlab-plot-skill"

  mkdir -p "${destination_root}"

  if [[ -e "${destination}" || -L "${destination}" ]]; then
    if [[ "${force}" != "true" ]]; then
      echo "Destination already exists: ${destination}. Re-run with --force to replace it." >&2
      exit 1
    fi

    rm -rf "${destination}"
  fi

  cp -R "${skill_source}" "${destination}"
  echo "Installed matlab-plot-skill to ${destination}"
}

warn_legacy_codex_copy() {
  # Older versions of this installer used Codex's deprecated user skills
  # directory ($CODEX_HOME/skills, default ~/.codex/skills). Codex still loads
  # skills from there, so an old copy shows up as a duplicate, stale skill.
  # Warn only; never delete it automatically.
  local legacy_root="${CODEX_HOME:-${HOME}/.codex}/skills"
  local legacy="${legacy_root}/matlab-plot-skill"
  if [[ ! -e "${legacy}" && ! -L "${legacy}" ]]; then
    return
  fi
  if [[ -d "${codex_skills_path}" && -d "${legacy_root}" ]] \
    && [[ "$(cd "${codex_skills_path}" && pwd -P)" == "$(cd "${legacy_root}" && pwd -P)" ]]; then
    return  # The caller installed into the legacy directory on purpose.
  fi
  echo "Warning: an older copy of matlab-plot-skill is still installed at ${legacy}." >&2
  echo "Codex also loads skills from that deprecated location and will list the skill twice." >&2
  echo "Remove the old copy with: rm -rf \"${legacy}\"" >&2
}

# Claude Code watches skill directories that existed when a session started;
# a newly created top-level skills directory needs /reload-skills (and again
# after each later change) until a new session starts.
claude_root_existed="false"
if [[ -d "${claude_skills_path}" ]]; then
  claude_root_existed="true"
fi

claude_message() {
  if [[ "${claude_root_existed}" == "true" ]]; then
    echo "Claude Code picks up the skill automatically, including in open sessions."
  else
    echo "Claude Code: ${claude_skills_path} was just created, so run /reload-skills in any open session (new sessions load it automatically)."
  fi
}

# Check every destination before copying anything, so a refused destination
# never leaves a half-finished install behind.
case "${target}" in
  codex) check_destination "${codex_skills_path}" ;;
  claude) check_destination "${claude_skills_path}" ;;
  both)
    check_destination "${codex_skills_path}"
    check_destination "${claude_skills_path}"
    ;;
esac

case "${target}" in
  codex)
    install_skill "${codex_skills_path}"
    warn_legacy_codex_copy
    ;;
  claude)
    install_skill "${claude_skills_path}"
    ;;
  both)
    install_skill "${codex_skills_path}"
    install_skill "${claude_skills_path}"
    warn_legacy_codex_copy
    ;;
  *)
    echo "Invalid target: ${target}. Expected codex, claude, or both." >&2
    exit 1
    ;;
esac

if [[ "${target}" != "codex" ]]; then
  claude_message
fi
if [[ "${target}" != "claude" ]]; then
  echo "Codex detects the new skill automatically; restart Codex if it does not appear."
fi
