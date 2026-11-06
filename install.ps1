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

function Get-PhysicalPath {
    # Return the full path with every symlink or junction along it resolved, so
    # two spellings of the same folder compare equal. Resolve-Path and
    # [IO.Path]::GetFullPath do not follow links. Works in PowerShell 5.1 and 7.
    param([string]$Path)
    $current = [System.IO.Path]::GetFullPath(
        $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path))
    for ($hop = 0; $hop -lt 64; $hop++) {
        $root = [System.IO.Path]::GetPathRoot($current)
        $parts = @($current.Substring($root.Length) -split '[\\/]' | Where-Object { $_ })
        $resolved = $root
        $relinked = $false
        for ($i = 0; $i -lt $parts.Count; $i++) {
            $next = Join-Path $resolved $parts[$i]
            $item = Get-Item -LiteralPath $next -Force -ErrorAction SilentlyContinue
            if ($item -and ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -and $item.Target) {
                $target = @($item.Target)[0]
                if (-not [System.IO.Path]::IsPathRooted($target)) {
                    $target = Join-Path $resolved $target
                }
                foreach ($part in @($parts | Select-Object -Skip ($i + 1))) {
                    $target = Join-Path $target $part
                }
                $current = [System.IO.Path]::GetFullPath($target)
                $relinked = $true
                break
            }
            $resolved = $next
        }
        if (-not $relinked) {
            return $resolved
        }
    }
    return $current
}

function Test-PathInside {
    # True when $Path is $Folder or lies inside it (case-insensitive, so the
    # check errs on the side of refusing).
    param([string]$Path, [string]$Folder)
    $separator = [System.IO.Path]::DirectorySeparatorChar
    $pathPrefix = $Path.TrimEnd('\', '/') + $separator
    $folderPrefix = $Folder.TrimEnd('\', '/') + $separator
    return $pathPrefix.StartsWith($folderPrefix, [System.StringComparison]::OrdinalIgnoreCase)
}

function Assert-SafeDestination {
    param(
        [string]$DestinationRoot
    )

    New-Item -ItemType Directory -Force -Path $DestinationRoot | Out-Null
    $destination = Join-Path $DestinationRoot 'matlab-plot-skill'
    $existing = Get-Item -LiteralPath $destination -Force -ErrorAction SilentlyContinue
    $existingIsLink = $existing -and ($existing.Attributes -band [System.IO.FileAttributes]::ReparsePoint)

    # Refuse when the destination is this clone or holds it (for example a clone
    # made directly in ~\.claude\skills\matlab-plot-skill, or -CodexSkillsPath
    # set to the repo root): replacing it would delete the clone, .git and local
    # edits included. A destination that is itself a link is not followed:
    # -Force removes only the link.
    if (-not $existingIsLink) {
        $destinationReal = Join-Path (Get-PhysicalPath $DestinationRoot) 'matlab-plot-skill'
        $repoReal = Get-PhysicalPath $repoRoot
        if (Test-PathInside -Path $repoReal -Folder $destinationReal) {
            throw ("Refusing to install into ${destination}: that folder holds this clone ($repoReal), " +
                'and replacing it would delete the clone. Clone the repo outside your skills folders ' +
                '(for example ~\src\matlab-plot-skill) and run the installer from there.')
        }
        if (Test-PathInside -Path $destinationReal -Folder (Join-Path $repoReal 'matlab-plot-skill')) {
            throw ("Refusing to install into ${destination}: that is this clone's own skill folder " +
                'or a folder inside it. Pick a skills directory outside the clone.')
        }
    }
}

function Install-Skill {
    param(
        [string]$DestinationRoot
    )

    New-Item -ItemType Directory -Force -Path $DestinationRoot | Out-Null
    $destination = Join-Path $DestinationRoot 'matlab-plot-skill'

    $existing = Get-Item -LiteralPath $destination -Force -ErrorAction SilentlyContinue
    $existingIsLink = $existing -and ($existing.Attributes -band [System.IO.FileAttributes]::ReparsePoint)

    if ($existing) {
        if (-not $Force) {
            throw "Destination already exists: $destination. Re-run with -Force to replace it."
        }

        if ($existingIsLink) {
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
    # Compare physical paths: when ~\.codex\skills is a link to ~\.agents\skills,
    # the "old copy" is the one just installed and must not be flagged.
    $installedRoot = (Get-PhysicalPath $CodexSkillsPath).TrimEnd('\', '/')
    $legacyResolved = (Get-PhysicalPath $legacyRoot).TrimEnd('\', '/')
    if ([string]::Equals($installedRoot, $legacyResolved, [System.StringComparison]::OrdinalIgnoreCase)) {
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

# Check every destination before copying anything, so a refused destination
# never leaves a half-finished install behind.
switch ($Target) {
    'codex' { Assert-SafeDestination -DestinationRoot $CodexSkillsPath }
    'claude' { Assert-SafeDestination -DestinationRoot $ClaudeSkillsPath }
    'both' {
        Assert-SafeDestination -DestinationRoot $CodexSkillsPath
        Assert-SafeDestination -DestinationRoot $ClaudeSkillsPath
    }
}

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
