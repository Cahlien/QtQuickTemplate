# bootstrap.ps1 — one-command dev environment setup for QtQuickTemplate (Windows)
# Installs uv into tools\ (if needed), downloads the pinned Python, and syncs
# all dependencies. Idempotent — safe to re-run at any time.

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path $PSScriptRoot -Parent
Set-Location $ProjectRoot

$UV = Join-Path $PSScriptRoot "uv.exe"

function Write-Info  { Write-Host "[bootstrap] $args" -ForegroundColor Cyan }
function Write-Ok    { Write-Host "[bootstrap] $args" -ForegroundColor Green }

# ── Step 1: Ensure uv is installed ───────────────────────────────────────────
if (-not (Test-Path $UV)) {
    Write-Info "uv not found — installing..."
    $env:UV_UNMANAGED_INSTALL = $PSScriptRoot
    try {
        irm https://astral.sh/uv/install.ps1 | iex
    } finally {
        Remove-Item Env:\UV_UNMANAGED_INSTALL
    }

    if (-not (Test-Path $UV)) {
        Write-Error "uv installed but not found at $UV."
        exit 1
    }
    Write-Ok "uv installed: $(& $UV --version)"
} else {
    Write-Ok "uv already installed: $(& $UV --version)"
}

# ── Step 2: Install the pinned Python ────────────────────────────────────────
$pythonVersion = Get-Content .python-version -Raw
Write-Info "Ensuring pinned Python is available (.python-version -> $($pythonVersion.Trim()))..."
& $UV python install
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Ok "Python ready: $(& $UV run python --version)"

# ── Step 3: Sync dependencies (creates/updates .venv/) ──────────────────────
Write-Info "Syncing dependencies..."
& $UV sync
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Ok "Virtual environment ready at .venv/"

# ── Step 4: Verify key tools ────────────────────────────────────────────────
Write-Info "Verifying tools..."
& $UV run cmake   --version | Select-Object -First 1
& $UV run conan   --version | Select-Object -First 1
& $UV run pytest  --version | Select-Object -First 1
Write-Ok "All tools verified."

# ── Step 5: Install bundletool (Android AAB/APK tooling) ───────────────────
$BundletoolVersion = "1.18.3"
$BundletoolJar = Join-Path $PSScriptRoot "bundletool-all-$BundletoolVersion.jar"
if (-not (Test-Path $BundletoolJar)) {
    Write-Info "Downloading bundletool $BundletoolVersion..."
    Invoke-WebRequest -Uri "https://github.com/google/bundletool/releases/download/$BundletoolVersion/bundletool-all-$BundletoolVersion.jar" -OutFile $BundletoolJar
    Write-Ok "Installed bundletool $BundletoolVersion"
} else {
    Write-Ok "bundletool $BundletoolVersion already installed"
}

# ── Done ─────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Bootstrap complete!" -ForegroundColor White -BackgroundColor DarkGreen

if (-not (Test-Path (Join-Path $ProjectRoot ".env.local"))) {
    Write-Host ""
    Write-Host "Next step: " -ForegroundColor Yellow -NoNewline
    Write-Host "Run .\tools\configure_env.ps1 to set Qt SDK paths and signing credentials."
}

Write-Host ""
Write-Host "Run commands through the env-aware wrapper with '.\tools\run.ps1':"
Write-Host "  .\tools\run.ps1 cmake --preset <preset>         # configure"
Write-Host "  .\tools\run.ps1 cmake --build --preset <preset>  # build"
Write-Host "  .\tools\run.ps1 conan install .                  # install C++ deps"
Write-Host "  .\tools\run.ps1 pytest                           # run tests"
Write-Host ""
Write-Host "Or activate the venv directly:"
Write-Host "  .venv\Scripts\Activate.ps1"
