<#
.SYNOPSIS
    Create (or recreate) the per-version dev virtualenvs used by VS Code.

.DESCRIPTION
    Installs uv-managed CPython 3.11 / 3.12 / 3.13, then builds one venv per
    minor version (.venv311 / .venv312 / .venv313), each with the pinned
    scriptkit installed. VS Code uses these for IntelliSense, linting, and
    debugging (default: .venv313); `uv run` still fetches each script's own
    PEP 723 pin when you actually run it.

.PARAMETER Tag
    scriptkit release tag to install into each venv (default: v0.2.1).

.PARAMETER Force
    Delete and recreate venvs that already exist.

.EXAMPLE
    .\setup-venvs.ps1
    .\setup-venvs.ps1 -Tag v0.2.0 -Force
#>
[CmdletBinding()]
param(
    [string]$Tag = "v0.2.1",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$versions = "3.11", "3.12", "3.13"
$scriptkit = "scriptkit @ git+https://github.com/acalderhead/py-scriptkit.git@$Tag"

# All three interpreters come from uv's reproducible standalone builds.
Write-Host "Installing uv-managed CPython $($versions -join ', ')..."
uv python install @versions

foreach ($v in $versions) {
    $name = ".venv" + ($v -replace '\.', '')
    $path = Join-Path $PSScriptRoot $name

    if (Test-Path $path) {
        if ($Force) {
            Write-Host "Removing existing $name..."
            Remove-Item -Recurse -Force $path
        } else {
            Write-Host "$name already exists (pass -Force to recreate); updating scriptkit only."
        }
    }

    if (-not (Test-Path $path)) {
        Write-Host "Creating $name (Python $v, uv-managed)..."
        uv venv --python-preference only-managed --python $v $path
    }

    Write-Host "Installing scriptkit@$Tag into $name..."
    uv pip install --python (Join-Path $path "Scripts\python.exe") $scriptkit
}

Write-Host ""
Write-Host "Done. VS Code default interpreter: .venv313"
Write-Host "Switch versions via 'Python: Select Interpreter' or the versioned debug configs."
