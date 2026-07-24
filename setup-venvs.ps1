<#
.SYNOPSIS
    Create (or recreate) the per-version dev virtualenvs used by VS Code.

.DESCRIPTION
    Installs uv-managed CPython 3.11 / 3.12 / 3.13, then builds one venv per
    minor version (.venv311 / .venv312 / .venv313). Each venv gets the pinned
    scriptkit[rich] (so the ▶ Run button and F5 debugging show RichLogger's
    decorated output, matching `uv run`) plus the dev tools (pytest, ruff) so the
    lint / test tasks work. VS Code uses these for IntelliSense, linting,
    testing, and debugging (default: .venv313); `uv run` still fetches each
    script's own PEP 723 pin when you actually run it, independent of these
    venvs.

.PARAMETER Tag
    scriptkit release tag to install into each venv (default: v0.2.3).

.PARAMETER Force
    Delete and recreate venvs that already exist.

.EXAMPLE
    .\setup-venvs.ps1
    .\setup-venvs.ps1 -Tag v0.2.1 -Force
#>
[CmdletBinding()]
param(
    [string]$Tag = "v0.2.3",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Run uv and fail only on a non-zero exit code. Two Windows PowerShell quirks
# are handled here:
#   1. A plain $args splat (not a declared parameter) so uv flags like -e pass
#      straight through — an advanced function would try to bind -e to a common
#      parameter (-ErrorAction/-ErrorVariable) and error out as ambiguous.
#   2. `2>&1 | ForEach-Object { "$_" }` funnels uv's stderr progress (e.g. "All
#      requested versions already installed") into the output stream as plain
#      text, so it neither shows as a red error nor trips ErrorActionPreference
#      on re-runs. The real success/failure signal is $LASTEXITCODE.
function Invoke-Uv {
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & uv @args 2>&1 | ForEach-Object { "$_" }
    } finally {
        $ErrorActionPreference = $prev
    }
    if ($LASTEXITCODE -ne 0) {
        throw "uv $($args -join ' ') failed (exit $LASTEXITCODE)."
    }
}

$versions = "3.11", "3.12", "3.13"
# The [rich] extra pulls rich_logger so the editor/debugger render decorated
# console output, the same as `uv run` on a script whose header pins the extra.
$scriptkit = "scriptkit[rich] @ git+https://github.com/acalderhead/py-scriptkit.git@$Tag"
# Dev tooling for the lint / test tasks (kept in sync with scriptkit's own dev
# extras). These are editor/CI tools only — never a runtime dependency of a
# script, which pins what it needs in its own PEP 723 header.
$devTools = "pytest>=8", "ruff>=0.6"

# All three interpreters come from uv's reproducible standalone builds.
Write-Host "Installing uv-managed CPython $($versions -join ', ')..."
Invoke-Uv python install @versions

foreach ($v in $versions) {
    $name = ".venv" + ($v -replace '\.', '')
    $path = Join-Path $PSScriptRoot $name

    if (Test-Path $path) {
        if ($Force) {
            Write-Host "Removing existing $name..."
            Remove-Item -Recurse -Force $path
        } else {
            Write-Host "$name already exists (pass -Force to recreate); updating packages only."
        }
    }

    if (-not (Test-Path $path)) {
        Write-Host "Creating $name (Python $v, uv-managed)..."
        Invoke-Uv venv --python-preference only-managed --python $v $path
    }

    Write-Host "Installing scriptkit@$Tag + dev tools into $name..."
    $py = Join-Path $path "Scripts\python.exe"
    Invoke-Uv pip install --python $py $scriptkit @devTools
}

Write-Host ""
Write-Host "Done. VS Code default interpreter: .venv313"
Write-Host "Switch versions via 'Python: Select Interpreter' or the versioned debug configs."
