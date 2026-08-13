<#
.SYNOPSIS
    Scaffold a new pytest file from scriptkit's test template.

.DESCRIPTION
    With -Name, creates tests/test_<name>.py directly. With no -Name (the .bat
    double-click), runs interactively: pick an existing script to test, or name
    a brand-new test file. On a name collision it explains and re-prompts rather
    than overwriting. The template comes from the sibling py-scriptkit repo
    (local checkout if present, otherwise GitHub raw at -Tag).

.PARAMETER Name
    Optional. A leading "test_" is stripped and re-added (e.g. "reconcile" ->
    test_reconcile.py). Omit for the interactive flow.

.PARAMETER Tag
    scriptkit release tag for the GitHub-raw template fallback (default: v1.0.0).

.PARAMETER Force
    Overwrite an existing file (honored only with -Name).

.EXAMPLE
    .\new-test.ps1                 # interactive
    .\new-test.ps1 reconcile       # -> tests/test_reconcile.py
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Name,
    [string]$Tag = "v1.0.0",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$testsDir = Join-Path $PSScriptRoot "tests"

# Normalize to a snake_case stem; drop any leading "test_" so it is added once.
function Get-TestStem([string]$raw) {
    ($raw -replace '\.py$', '' -replace '^test_', '' -replace '[^A-Za-z0-9]+', '_').Trim('_').ToLower()
}

# Existing script/module files that could be tested (recurses scripts\ + src\).
function Find-SourceFiles {
    $files = @()
    foreach ($dir in @("scripts", "src")) {
        $root = Join-Path $PSScriptRoot $dir
        if (Test-Path $root) {
            $found = Get-ChildItem $root -Recurse -File -Filter *.py
            $files += $found | Where-Object { $_.Name -notlike "test_*" -and $_.Name -ne "__init__.py" -and $_.FullName -notmatch '[\\/](tests|templates)[\\/]' }
        }
    }
    $files | Sort-Object Name
}

# Read the test template from the sibling py-scriptkit repo, or GitHub raw.
function Get-TestTemplate {
    $local = Join-Path $PSScriptRoot "..\py-scriptkit\src\scriptkit\templates\test_template.py"
    if (Test-Path $local) {
        Write-Host "Template: local py-scriptkit ($local)"
        return [System.IO.File]::ReadAllText($local)
    }
    $url = "https://raw.githubusercontent.com/acalderhead/py-scriptkit/$Tag/src/scriptkit/templates/test_template.py"
    Write-Host "Template: GitHub raw @ $Tag"
    return (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
}

$stem = $null

if ($Name) {
    $stem = Get-TestStem $Name
    if (-not $stem) { throw "Could not derive a filename from '$Name'." }
    $dest = Join-Path $testsDir "test_$stem.py"
    if ((Test-Path $dest) -and -not $Force) {
        throw "Refusing to overwrite $dest (pass -Force to replace it)."
    }
} else {
    $answer = Read-Host "Create a test for an EXISTING script/module file? [y/N]"
    if ($answer -match '^\s*[Yy]') {
        $candidates = @(Find-SourceFiles)
        if ($candidates.Count -eq 0) {
            Write-Host "No source files found under scripts\ or src\; name a new test instead."
        } else {
            while (-not $stem) {
                Write-Host ""
                Write-Host "Select a file to create a test for:"
                for ($i = 0; $i -lt $candidates.Count; $i++) {
                    Write-Host ("  [{0}] {1}" -f ($i + 1), $candidates[$i].Name)
                }
                $pick = Read-Host "Number (blank to cancel)"
                if ([string]::IsNullOrWhiteSpace($pick)) { Write-Host "Cancelled."; return }
                $index = 0
                if (-not [int]::TryParse($pick, [ref] $index) -or $index -lt 1 -or $index -gt $candidates.Count) {
                    Write-Host "  '$pick' is not a valid choice; try again."
                    continue
                }
                $candidateStem = Get-TestStem $candidates[$index - 1].BaseName
                $dest = Join-Path $testsDir "test_$candidateStem.py"
                if (Test-Path $dest) {
                    Write-Host "  A test already exists for that file (tests\test_$candidateStem.py); pick another."
                    continue
                }
                $stem = $candidateStem
            }
        }
    }

    if (-not $stem) {
        Write-Host ""
        Write-Host "Note: 'test_' is prepended to the name, e.g. 'foo' -> test_foo.py."
        while (-not $stem) {
            $raw = Read-Host "Name for the new test"
            $candidateStem = Get-TestStem $raw
            if (-not $candidateStem) { Write-Host "  Please enter a valid name."; continue }
            $dest = Join-Path $testsDir "test_$candidateStem.py"
            if (Test-Path $dest) {
                Write-Host "  test_$candidateStem.py already exists; choose a different name."
                continue
            }
            $stem = $candidateStem
        }
    }
}

if (-not (Test-Path $testsDir)) { New-Item -ItemType Directory -Path $testsDir | Out-Null }

# Write UTF-8 without BOM to match the rest of the repo.
$content = Get-TestTemplate
[System.IO.File]::WriteAllText($dest, $content, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ""
Write-Host "Created tests/test_$stem.py"
Write-Host "Next:  edit tests/test_$stem.py and write the tests."
