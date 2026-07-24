<#
.SYNOPSIS
    Scaffold a new scriptkit-based script from the canonical template.

.DESCRIPTION
    Copies templates/script_template.py from the py-scriptkit source of truth
    (the local sibling repo if present, otherwise GitHub raw at the given tag)
    into this repo's scripts/ folder, names it, and pins its scriptkit
    dependency to -Tag. This is the only step needed to start a new script —
    the CLI, env wiring, path cascade, and logging are inherited from scriptkit.

.PARAMETER Name
    Name for the new script; punctuation is normalized to snake_case and a .py
    extension is added (e.g. "Reconcile Invoices" -> reconcile_invoices.py).

.PARAMETER Tag
    scriptkit release tag to pin the new script to (default: v0.2.0).

.PARAMETER Force
    Overwrite an existing file of the same name.

.EXAMPLE
    .\new-script.ps1 reconcile_invoices
    .\new-script.ps1 "Backup Photos" -Tag v0.2.0
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Name,
    [string]$Tag = "v0.2.0",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Normalize to a snake_case .py filename.
$stem = ($Name -replace '\.py$', '' -replace '[^A-Za-z0-9]+', '_').Trim('_').ToLower()
if (-not $stem) { throw "Could not derive a filename from '$Name'." }

# Always write into this repo's scripts/ folder, regardless of current directory.
$scriptsDir = Join-Path $PSScriptRoot "scripts"
if (-not (Test-Path $scriptsDir)) { New-Item -ItemType Directory -Path $scriptsDir | Out-Null }
$dest = Join-Path $scriptsDir "$stem.py"
if ((Test-Path $dest) -and -not $Force) {
    throw "Refusing to overwrite $dest (pass -Force to replace it)."
}

# Prefer the local sibling repo; fall back to GitHub raw at the requested tag.
$local = Join-Path $PSScriptRoot "..\py-scriptkit\templates\script_template.py"
if (Test-Path $local) {
    # Read as UTF-8 explicitly. Windows PowerShell 5.1's Get-Content defaults to
    # the ANSI codepage and would corrupt non-ASCII characters (e.g. the box-
    # drawing separators in the template docstring).
    $content = [System.IO.File]::ReadAllText($local)
    Write-Host "Template: local py-scriptkit ($local)"
} else {
    $url = "https://raw.githubusercontent.com/acalderhead/py-scriptkit/$Tag/templates/script_template.py"
    $content = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
    Write-Host "Template: GitHub raw @ $Tag"
}

# Pin the new script to the requested tag.
$content = $content -replace 'py-scriptkit\.git@v[0-9]+\.[0-9]+\.[0-9]+', "py-scriptkit.git@$Tag"

# Write UTF-8 without BOM so `uv run` / the shebang parse cleanly.
[System.IO.File]::WriteAllText($dest, $content, (New-Object System.Text.UTF8Encoding($false)))

Write-Host "Created scripts/$stem.py (pinned scriptkit@$Tag)"
Write-Host "Next:  uv run scripts/$stem.py --help"
