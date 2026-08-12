<#
.SYNOPSIS
    Scaffold a new scriptkit-based script from the canonical template.

.DESCRIPTION
    Copies script_template.py from the py-scriptkit source of truth (the local
    sibling repo if present, otherwise GitHub raw at -Tag) into this repo's
    scripts/ folder, and pins its scriptkit dependency to -Tag. With -Name it
    writes directly; with no -Name (the .bat double-click) it prompts, and on a
    name collision it explains and re-prompts rather than overwriting.

.PARAMETER Name
    Optional. Normalized to a snake_case filename (e.g. "Reconcile Invoices" ->
    reconcile_invoices.py). Omit for the interactive prompt.

.PARAMETER Tag
    scriptkit release tag to pin the new script to (default: v0.5.4).

.PARAMETER Force
    Overwrite an existing file (honored only with -Name).

.EXAMPLE
    .\new-script.ps1                       # interactive
    .\new-script.ps1 reconcile_invoices
    .\new-script.ps1 "Backup Photos" -Tag v0.2.0
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Name,
    [string]$Tag = "v0.5.4",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$scriptsDir = Join-Path $PSScriptRoot "scripts"

# Normalize to a snake_case stem.
function Get-Stem([string]$raw) {
    ($raw -replace '\.py$', '' -replace '[^A-Za-z0-9]+', '_').Trim('_').ToLower()
}

# Read the script template from the sibling py-scriptkit repo, or GitHub raw.
function Get-ScriptTemplate {
    $local = Join-Path $PSScriptRoot "..\py-scriptkit\src\scriptkit\templates\script_template.py"
    if (Test-Path $local) {
        Write-Host "Template: local py-scriptkit ($local)"
        return [System.IO.File]::ReadAllText($local)
    }
    $url = "https://raw.githubusercontent.com/acalderhead/py-scriptkit/$Tag/src/scriptkit/templates/script_template.py"
    Write-Host "Template: GitHub raw @ $Tag"
    return (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
}

$stem = $null

if ($Name) {
    $stem = Get-Stem $Name
    if (-not $stem) { throw "Could not derive a filename from '$Name'." }
    $dest = Join-Path $scriptsDir "$stem.py"
    if ((Test-Path $dest) -and -not $Force) {
        throw "Refusing to overwrite $dest (pass -Force to replace it)."
    }
} else {
    while (-not $stem) {
        $raw = Read-Host "Name for the new script"
        $candidateStem = Get-Stem $raw
        if (-not $candidateStem) { Write-Host "  Please enter a valid name."; continue }
        $dest = Join-Path $scriptsDir "$candidateStem.py"
        if (Test-Path $dest) {
            Write-Host "  scripts\$candidateStem.py already exists; choose a different name."
            continue
        }
        $stem = $candidateStem
    }
}

if (-not (Test-Path $scriptsDir)) { New-Item -ItemType Directory -Path $scriptsDir | Out-Null }

# Pin the new script to the requested tag, then write UTF-8 without BOM so
# `uv run` / the shebang parse cleanly.
$content = Get-ScriptTemplate
$content = $content -replace 'py-scriptkit\.git@v[0-9]+\.[0-9]+\.[0-9]+', "py-scriptkit.git@$Tag"
[System.IO.File]::WriteAllText($dest, $content, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ""
Write-Host "Created scripts/$stem.py (pinned scriptkit@$Tag)"
Write-Host "Next:  uv run --exact scripts/$stem.py --help"
