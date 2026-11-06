<#
.SYNOPSIS
Install matlab-plot-skill into the Codex and/or Claude Code skill directories.

.DESCRIPTION
Copies the matlab-plot-skill folder from this clone into ~/.agents/skills
(Codex) and/or ~/.claude/skills (Claude Code). Use -Force to replace an
existing installed copy. Run Get-Help .\install.ps1 for this text.

.EXAMPLE
.\install.ps1

.EXAMPLE
.\install.ps1 -Target codex -Force
#>
param(
    [ValidateSet('codex', 'claude', 'both')]
    [string]$Target = 'both',
    [string]$CodexSkillsPath = (Join-Path $HOME '.agents\skills'),
    [string]$ClaudeSkillsPath = (Join-Path $HOME '.claude\skills'),
    [switch]$Force
)

# Stop on the first failed command so a failed copy is never reported as installed.
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$skillSource = Join-Path $repoRoot 'matlab-plot-skill'

if (-not (Test-Path -LiteralPath $skillSource)) {
    throw "Skill source not found: $skillSource"
}

function Install-Skill {
    param(
        [string]$DestinationRoot
    )

    New-Item -ItemType Directory -Force -Path $DestinationRoot | Out-Null
    $destination = Join-Path $DestinationRoot 'matlab-plot-skill'

    $existing = Get-Item -LiteralPath $destination -Force -ErrorAction SilentlyContinue
    if ($existing) {
        if (-not $Force) {
            throw "Destination already exists: $destination. Re-run with -Force to replace it."
        }

        if ($existing.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            # A symlink or junction: remove only the link. Remove-Item -Recurse
            # on a link can delete the target's contents in Windows PowerShell 5.1.
            $existing.Delete()
        }
        else {
            Remove-Item -LiteralPath $destination -Recurse -Force
        }
    }

    Copy-Item -LiteralPath $skillSource -Destination $destination -Recurse -Force
    Write-Host "Installed matlab-plot-skill to $destination"
}

function Test-LegacyCodexCopy {
    # Older versions of this installer used Codex's deprecated user skills
    # directory ($CODEX_HOME\skills, default ~\.codex\skills). Codex still loads
    # skills from there, so an old copy shows up as a duplicate, stale skill.
    # Warn only; never delete it automatically.
    $codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }
    $legacyRoot = Join-Path $codexHome 'skills'
    $legacy = Join-Path $legacyRoot 'matlab-plot-skill'
    $legacyItem = Get-Item -LiteralPath $legacy -Force -ErrorAction SilentlyContinue
    if (-not $legacyItem) {
        return
    }
    $installedRoot = (Resolve-Path -LiteralPath $CodexSkillsPath).ProviderPath.TrimEnd('\', '/')
    $legacyResolved = (Resolve-Path -LiteralPath $legacyRoot).ProviderPath.TrimEnd('\', '/')
    if ($installedRoot -eq $legacyResolved) {
        return  # The caller installed into the legacy directory on purpose.
    }
    Write-Warning "An older copy of matlab-plot-skill is still installed at $legacy."
    Write-Warning 'Codex also loads skills from that deprecated location and will list the skill twice.'
    if ($legacyItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        # A symlink or junction (e.g. to a clone): suggest removing only the link,
        # since Remove-Item -Recurse on a link can delete the target's contents
        # in Windows PowerShell 5.1.
        Write-Warning "It is a link; remove only the link with: (Get-Item -LiteralPath '$legacy' -Force).Delete()"
    }
    else {
        Write-Warning "Remove the old copy with: Remove-Item -LiteralPath '$legacy' -Recurse -Force"
    }
}

# Claude Code watches skill directories that existed when a session started;
# a newly created top-level skills directory needs /reload-skills (and again
# after each later change) until a new session starts.
$claudeRootExisted = Test-Path -LiteralPath $ClaudeSkillsPath

switch ($Target) {
    'codex' {
        Install-Skill -DestinationRoot $CodexSkillsPath
        Test-LegacyCodexCopy
    }
    'claude' { Install-Skill -DestinationRoot $ClaudeSkillsPath }
    'both' {
        Install-Skill -DestinationRoot $CodexSkillsPath
        Install-Skill -DestinationRoot $ClaudeSkillsPath
        Test-LegacyCodexCopy
    }
}

if ($Target -ne 'codex') {
    if ($claudeRootExisted) {
        Write-Host 'Claude Code picks up the skill automatically, including in open sessions.'
    }
    else {
        Write-Host "Claude Code: $ClaudeSkillsPath was just created, so run /reload-skills in any open session (new sessions load it automatically)."
    }
}
if ($Target -ne 'claude') {
    Write-Host 'Codex detects the new skill automatically; restart Codex if it does not appear.'
}
