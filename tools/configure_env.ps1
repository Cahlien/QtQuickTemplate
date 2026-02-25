# tools/configure_env.ps1 — interactive wizard that writes .env.local
# with developer-specific SDK paths and signing credentials.

$ErrorActionPreference = "Stop"

$ScriptDir   = $PSScriptRoot
$ProjectRoot = Split-Path $ScriptDir -Parent
$EnvLocal    = Join-Path $ProjectRoot ".env.local"

# ── Load existing .env.local as defaults ─────────────────────────────────────
$Defaults = [ordered]@{}
if (Test-Path $EnvLocal) {
    Write-Host "[configure_env] Loading existing .env.local for defaults..." -ForegroundColor Cyan
    foreach ($line in Get-Content $EnvLocal) {
        if ($line -match '^\s*#' -or [string]::IsNullOrWhiteSpace($line)) { continue }
        $eqIdx = $line.IndexOf('=')
        if ($eqIdx -gt 0) {
            $key   = $line.Substring(0, $eqIdx)
            $value = $line.Substring($eqIdx + 1)
            $Defaults[$key] = $value
        }
    }
}

# ── Prompt helper ────────────────────────────────────────────────────────────
$Result = [ordered]@{}

function Prompt-Var {
    param(
        [string]$VarName,
        [string]$Description,
        [string]$DefaultOverride = ""
    )
    $default = if ($Defaults.Contains($VarName)) { $Defaults[$VarName] }
               elseif ($DefaultOverride) { $DefaultOverride }
               else { "" }

    if ($default) {
        $input = Read-Host "  $Description ($VarName) [$default]"
    } else {
        $input = Read-Host "  $Description ($VarName)"
    }
    if ([string]::IsNullOrWhiteSpace($input)) { $input = $default }

    # Soft path validation
    if ($input -and ($Description -match 'path|root|Root|PATH|ROOT')) {
        if (-not (Test-Path $input -ErrorAction SilentlyContinue)) {
            Write-Host "    Path does not exist yet: $input (continuing anyway)" -ForegroundColor Yellow
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($input)) {
        $script:Result[$VarName] = $input
    }
}

# ── Auto-detect Android SDK/NDK from common Windows locations ────────────────
function Detect-AndroidSdk {
    $candidates = @(
        "$env:LOCALAPPDATA\Android\Sdk"
        "$env:USERPROFILE\AppData\Local\Android\Sdk"
        "C:\Android\Sdk"
    )
    foreach ($dir in $candidates) {
        if ($dir -and (Test-Path $dir -ErrorAction SilentlyContinue)) {
            return $dir
        }
    }
    # Fallback: check environment variables
    if ($env:ANDROID_SDK_ROOT -and (Test-Path $env:ANDROID_SDK_ROOT -ErrorAction SilentlyContinue)) {
        return $env:ANDROID_SDK_ROOT
    }
    if ($env:ANDROID_HOME -and (Test-Path $env:ANDROID_HOME -ErrorAction SilentlyContinue)) {
        return $env:ANDROID_HOME
    }
    return ""
}

function Detect-AndroidNdk {
    param([string]$SdkRoot)
    if (-not $SdkRoot) { return "" }
    $ndkDir = Join-Path $SdkRoot "ndk"
    if (-not (Test-Path $ndkDir -ErrorAction SilentlyContinue)) { return "" }
    $latest = Get-ChildItem -Directory $ndkDir -ErrorAction SilentlyContinue |
              Sort-Object Name |
              Select-Object -Last 1
    if ($latest) { return $latest.FullName }
    return ""
}

function Detect-JavaHome {
    # Check JAVA_HOME env var first
    if ($env:JAVA_HOME -and (Test-Path $env:JAVA_HOME -ErrorAction SilentlyContinue)) {
        return $env:JAVA_HOME
    }
    # Search common Windows JDK locations
    $searchRoots = @(
        "C:\Program Files\Eclipse Adoptium"
        "C:\Program Files\Java"
    )
    foreach ($root in $searchRoots) {
        if (Test-Path $root -ErrorAction SilentlyContinue) {
            $jdk = Get-ChildItem -Directory $root -ErrorAction SilentlyContinue |
                   Where-Object { $_.Name -match 'jdk' } |
                   Sort-Object Name -Descending |
                   Select-Object -First 1
            if ($jdk) { return $jdk.FullName }
        }
    }
    # Try Microsoft JDK glob pattern
    $msJdks = Get-Item "C:\Program Files\Microsoft\jdk-*" -ErrorAction SilentlyContinue
    if ($msJdks) {
        $latest = $msJdks | Sort-Object Name -Descending | Select-Object -First 1
        return $latest.FullName
    }
    return ""
}

# ── Start ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "QtQuickTemplate - Developer Environment Configuration" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "Detected platform: Windows"
Write-Host "Values are written to .env.local (gitignored)."
Write-Host "Press Enter to keep the default shown in [brackets]."

# ── Qt SDK Paths ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "-- Qt SDK Paths --" -ForegroundColor White

Prompt-Var "QT_WINDOWS_ROOT" "Windows Qt SDK root (e.g. C:\Qt\6.10.2\msvc2022_64)"
Prompt-Var "QT_ANDROID_ROOT" "Android Qt SDK root (leave empty to skip)"
Prompt-Var "QT_HOST_ROOT"    "Host Qt root for cross-compilation (leave empty to skip)"

# Derive Qt6_DIR and CMAKE_PREFIX_PATH
if ($Result.Contains("QT_WINDOWS_ROOT")) {
    $Result["Qt6_DIR"] = "$($Result["QT_WINDOWS_ROOT"])\lib\cmake\Qt6"
    $Result["CMAKE_PREFIX_PATH"] = $Result["QT_WINDOWS_ROOT"]
    Write-Host "[configure_env] Derived Qt6_DIR=$($Result["Qt6_DIR"])" -ForegroundColor Cyan
    Write-Host "[configure_env] Derived CMAKE_PREFIX_PATH=$($Result["CMAKE_PREFIX_PATH"])" -ForegroundColor Cyan
}

# ── Android SDK & Signing ───────────────────────────────────────────────────
$hasAndroid = $Result.Contains("QT_ANDROID_ROOT") -or $Defaults.Contains("QT_ANDROID_ROOT")
if ($hasAndroid) {
    Write-Host ""
    Write-Host "-- Android SDK --" -ForegroundColor White

    $detectedSdk = Detect-AndroidSdk
    Prompt-Var "ANDROID_SDK_ROOT" "Android SDK root" $detectedSdk

    $sdkForNdk = if ($Result.Contains("ANDROID_SDK_ROOT")) { $Result["ANDROID_SDK_ROOT"] }
                 elseif ($Defaults.Contains("ANDROID_SDK_ROOT")) { $Defaults["ANDROID_SDK_ROOT"] }
                 else { "" }
    $detectedNdk = Detect-AndroidNdk $sdkForNdk
    Prompt-Var "ANDROID_NDK_ROOT" "Android NDK root" $detectedNdk

    $detectedJava = Detect-JavaHome
    Prompt-Var "JAVA_HOME" "Java JDK home (JDK 17+ recommended)" $detectedJava

    Write-Host ""
    Write-Host "-- Android Signing --" -ForegroundColor White

    Prompt-Var "ANDROID_KEYSTORE_PATH"     "Keystore file path"
    Prompt-Var "ANDROID_KEYSTORE_PASSWORD"  "Keystore password"
    Prompt-Var "ANDROID_KEY_ALIAS"          "Key alias"
    Prompt-Var "ANDROID_KEY_PASSWORD"       "Key password"

    Write-Host ""
    Write-Host "-- Google Play Upload --" -ForegroundColor White

    Prompt-Var "ANDROID_PLAY_SERVICE_ACCOUNT_FILE" "Play Console service account JSON path (leave empty to skip)"
    Prompt-Var "ANDROID_PLAY_TRACK"                "Play Console release track" "internal"
    Prompt-Var "ANDROID_PLAY_RELEASE_STATUS"       "Play Console release status" "completed"
}

# ── Write .env.local ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "-- Writing .env.local --" -ForegroundColor White

$lines = @()
$lines += "# Generated by tools/configure_env.ps1 on $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')"
$lines += "# Re-run the script to update. Manual edits are preserved as defaults."
$lines += ""

# Qt SDK Paths
$qtVars = @("QT_WINDOWS_ROOT", "QT_ANDROID_ROOT", "QT_HOST_ROOT", "Qt6_DIR", "CMAKE_PREFIX_PATH")
$hasQt = $false
foreach ($var in $qtVars) {
    if ($Result.Contains($var)) {
        if (-not $hasQt) { $lines += "# Qt SDK Paths"; $hasQt = $true }
        $lines += "$var=$($Result[$var])"
    }
}
if ($hasQt) { $lines += "" }

# Android SDK
$androidSdkVars = @("ANDROID_SDK_ROOT", "ANDROID_NDK_ROOT", "JAVA_HOME")
$hasAndroidSdk = $false
foreach ($var in $androidSdkVars) {
    if ($Result.Contains($var)) {
        if (-not $hasAndroidSdk) { $lines += "# Android SDK"; $hasAndroidSdk = $true }
        $lines += "$var=$($Result[$var])"
    }
}
if ($hasAndroidSdk) { $lines += "" }

# Android Signing
$androidSigningVars = @("ANDROID_KEYSTORE_PATH", "ANDROID_KEYSTORE_PASSWORD", "ANDROID_KEY_ALIAS", "ANDROID_KEY_PASSWORD")
$hasAndroidSigning = $false
foreach ($var in $androidSigningVars) {
    if ($Result.Contains($var)) {
        if (-not $hasAndroidSigning) { $lines += "# Android Signing"; $hasAndroidSigning = $true }
        $lines += "$var=$($Result[$var])"
    }
}
if ($hasAndroidSigning) { $lines += "" }

# Google Play Upload
$playVars = @("ANDROID_PLAY_SERVICE_ACCOUNT_FILE", "ANDROID_PLAY_TRACK", "ANDROID_PLAY_RELEASE_STATUS")
$hasPlay = $false
foreach ($var in $playVars) {
    if ($Result.Contains($var)) {
        if (-not $hasPlay) { $lines += "# Google Play Upload"; $hasPlay = $true }
        $lines += "$var=$($Result[$var])"
    }
}
if ($hasPlay) { $lines += "" }

$lines | Set-Content -Path $EnvLocal -Encoding UTF8

Write-Host "[configure_env] Wrote $EnvLocal" -ForegroundColor Green
Write-Host ""
Write-Host "You can now run builds with .\tools\run.ps1:"
Write-Host "  .\tools\run.ps1 cmake --preset <preset>         # configure"
Write-Host "  .\tools\run.ps1 cmake --build --preset <preset>  # build"
