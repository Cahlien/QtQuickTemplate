# tools/run.ps1 — wrapper around `uv run` that loads .env and .env.local
# Usage: .\tools\run.ps1 cmake --preset <name>
#        .\tools\run.ps1 pytest

$ErrorActionPreference = "Stop"

$ScriptDir  = $PSScriptRoot
$ProjectRoot = Split-Path $ScriptDir -Parent
$UV = Join-Path $ScriptDir "uv.exe"

$envFlags = @()

if (Test-Path (Join-Path $ProjectRoot ".env")) {
    $envFlags += "--env-file"
    $envFlags += (Join-Path $ProjectRoot ".env")
}

if (Test-Path (Join-Path $ProjectRoot ".env.local")) {
    $envFlags += "--env-file"
    $envFlags += (Join-Path $ProjectRoot ".env.local")
} else {
    # Warn when running cmake without .env.local
    if ($args -contains "cmake") {
        Write-Host "[run] .env.local not found - run .\tools\configure-env.ps1 to set SDK paths" -ForegroundColor Yellow
    }
}

& $UV run @envFlags @args
exit $LASTEXITCODE
