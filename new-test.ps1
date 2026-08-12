<#
.SYNOPSIS
    Scaffold a new pytest file from scriptkit's test template.

.DESCRIPTION
    Copies test_template.py from the py-scriptkit source of truth (the local
    sibling repo if present, otherwise GitHub raw at the given tag) into this
    repo's tests/ folder, named test_<name>.py. The test template carries no
    dependency pin, so nothing is repointed.

.PARAMETER Name
    Name for the module under test; punctuation is normalized to snake_case and
    a leading "test_" is stripped, then re-added (e.g. "reconcile" ->
    test_reconcile.py).

.PARAMETER Tag
    scriptkit release tag used only for the GitHub-raw fallback (default: v0.5.0).

.PARAMETER Force
    Overwrite an existing file of the same name.

.EXAMPLE
    .\new-test.ps1 reconcile
    .\new-test.ps1 test_stable_check -Force
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Name,
    [string]$Tag = "v0.5.3",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Normalize to a snake_case stem; drop any leading "test_" so it is added once.
$stem = ($Name -replace '\.py$', '' -replace '^test_', '' -replace '[^A-Za-z0-9]+', '_').Trim('_').ToLower()
if (-not $stem) { throw "Could not derive a filename from '$Name'." }

# Always write into this repo's tests/ folder, regardless of current directory.
$testsDir = Join-Path $PSScriptRoot "tests"
if (-not (Test-Path $testsDir)) { New-Item -ItemType Directory -Path $testsDir | Out-Null }
$dest = Join-Path $testsDir "test_$stem.py"
if ((Test-Path $dest) -and -not $Force) {
    throw "Refusing to overwrite $dest (pass -Force to replace it)."
}

# Prefer the local sibling repo; fall back to GitHub raw at the requested tag.
$local = Join-Path $PSScriptRoot "..\py-scriptkit\src\scriptkit\templates\test_template.py"
if (Test-Path $local) {
    # Read as UTF-8 explicitly. Windows PowerShell 5.1's Get-Content defaults to
    # the ANSI codepage and would corrupt non-ASCII characters (e.g. the box-
    # drawing separators in the template docstring).
    $content = [System.IO.File]::ReadAllText($local)
    Write-Host "Template: local py-scriptkit ($local)"
} else {
    $url = "https://raw.githubusercontent.com/acalderhead/py-scriptkit/$Tag/src/scriptkit/templates/test_template.py"
    $content = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
    Write-Host "Template: GitHub raw @ $Tag"
}

# Write UTF-8 without BOM to match the rest of the repo.
[System.IO.File]::WriteAllText($dest, $content, (New-Object System.Text.UTF8Encoding($false)))

Write-Host "Created tests/test_$stem.py"
Write-Host "Next:  edit tests/test_$stem.py and write the tests."
