param(
    [ValidateSet('codex', 'claude', 'both')]
    [string]$Target = 'both',
    [string]$CodexSkillsPath = (Join-Path $HOME '.codex\skills'),
    [string]$ClaudeSkillsPath = (Join-Path $HOME '.claude\skills'),
    [switch]$Force
)

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$skillSource = Join-Path $repoRoot 'matlab-plot-skill'

if (-not (Test-Path $skillSource)) {
    throw "Skill source not found: $skillSource"
}

function Install-Skill {
    param(
        [string]$DestinationRoot
    )

    New-Item -ItemType Directory -Force -Path $DestinationRoot | Out-Null
    $destination = Join-Path $DestinationRoot 'matlab-plot-skill'

    if (Test-Path $destination) {
        if (-not $Force) {
            throw "Destination already exists: $destination. Re-run with -Force to replace it."
        }

        Remove-Item -Recurse -Force $destination
    }

    Copy-Item -Recurse -Force $skillSource $destination
    Write-Host "Installed matlab-plot-skill to $destination"
}

switch ($Target) {
    'codex' { Install-Skill -DestinationRoot $CodexSkillsPath }
    'claude' { Install-Skill -DestinationRoot $ClaudeSkillsPath }
    'both' {
        Install-Skill -DestinationRoot $CodexSkillsPath
        Install-Skill -DestinationRoot $ClaudeSkillsPath
    }
}
