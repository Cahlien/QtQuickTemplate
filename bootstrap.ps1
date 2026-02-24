# bootstrap.ps1 — one-command dev environment setup for QtQuickTemplate (Windows)
# Installs uv (if needed), downloads the pinned Python, and syncs all dependencies.
# Idempotent — safe to re-run at any time.

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

function Write-Info  { Write-Host "[bootstrap] $args" -ForegroundColor Cyan }
function Write-Ok    { Write-Host "[bootstrap] $args" -ForegroundColor Green }

# ── Step 1: Ensure uv is installed ───────────────────────────────────────────
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Info "uv not found — installing..."
    irm https://astral.sh/uv/install.ps1 | iex

    # Refresh PATH from registry so the current session sees the new binary
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath    = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path    = "$userPath;$machinePath"

    if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
        Write-Error "uv installed but not found on PATH. Open a new terminal and re-run."
        exit 1
    }
    Write-Ok "uv installed: $(uv --version)"
} else {
    Write-Ok "uv already installed: $(uv --version)"
}

# ── Step 2: Install the pinned Python ────────────────────────────────────────
$pythonVersion = Get-Content .python-version -Raw
Write-Info "Ensuring pinned Python is available (.python-version -> $($pythonVersion.Trim()))..."
uv python install
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Ok "Python ready: $(uv run python --version)"

# ── Step 3: Sync dependencies (creates/updates .venv/) ──────────────────────
Write-Info "Syncing dependencies..."
uv sync
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Ok "Virtual environment ready at .venv/"

# ── Step 4: Verify key tools ────────────────────────────────────────────────
Write-Info "Verifying tools..."
uv run cmake   --version | Select-Object -First 1
uv run conan   --version | Select-Object -First 1
uv run pytest  --version | Select-Object -First 1
Write-Ok "All tools verified."

# ── Done ─────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Bootstrap complete!" -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "Run commands through the venv with 'uv run':"
Write-Host "  uv run cmake --preset <preset>         # configure"
Write-Host "  uv run cmake --build --preset <preset>  # build"
Write-Host "  uv run conan install .                  # install C++ deps"
Write-Host "  uv run pytest                           # run tests"
Write-Host ""
Write-Host "Or activate the venv directly:"
Write-Host "  .venv\Scripts\Activate.ps1"
