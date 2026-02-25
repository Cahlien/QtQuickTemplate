#!/usr/bin/env bash
# tools/configure-env.sh — interactive wizard that writes .env.local
# with developer-specific SDK paths and signing credentials.

set -euo pipefail

# Require bash 4+ for associative arrays
if (( BASH_VERSINFO[0] < 4 )); then
    echo "ERROR: bash 4+ required (you have ${BASH_VERSION}). On macOS: brew install bash" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_LOCAL="$PROJECT_ROOT/.env.local"
PLATFORM="$(uname -s)"

# ── Terminal colors ──────────────────────────────────────────────────────────
if [ -t 1 ]; then
    BOLD='\033[1m'
    GREEN='\033[0;32m'
    CYAN='\033[0;36m'
    YELLOW='\033[0;33m'
    RESET='\033[0m'
else
    BOLD='' GREEN='' CYAN='' YELLOW='' RESET=''
fi

info()  { printf "${CYAN}[configure-env]${RESET} %s\n" "$*"; }
ok()    { printf "${GREEN}[configure-env]${RESET} %s\n" "$*"; }
warn()  { printf "${YELLOW}[configure-env]${RESET} %s\n" "$*"; }
header(){ printf "\n${BOLD}── %s ──${RESET}\n" "$*"; }

# ── Load existing .env.local as defaults ─────────────────────────────────────
declare -A DEFAULTS
if [ -f "$ENV_LOCAL" ]; then
    info "Loading existing .env.local for defaults..."
    while IFS= read -r line; do
        # Skip comments and blank lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue
        key="${line%%=*}"
        value="${line#*=}"
        DEFAULTS["$key"]="$value"
    done < "$ENV_LOCAL"
fi

# ── Prompt helper ────────────────────────────────────────────────────────────
# prompt VAR_NAME "Description" [default]
# Sets result in the RESULT associative array
declare -A RESULT

prompt() {
    local var="$1" desc="$2" default="${3:-${DEFAULTS[$var]:-}}"
    local input

    if [ -n "$default" ]; then
        printf "  %s (%s) [%s]: " "$desc" "$var" "$default"
    else
        printf "  %s (%s): " "$desc" "$var"
    fi
    read -r input
    input="${input:-$default}"

    # Soft path validation
    if [ -n "$input" ] && [[ "$desc" == *path* || "$desc" == *root* || "$desc" == *Root* || "$desc" == *PATH* || "$desc" == *ROOT* ]]; then
        if [ ! -e "$input" ]; then
            warn "    Path does not exist yet: $input (continuing anyway)"
        fi
    fi

    if [ -n "$input" ]; then
        RESULT["$var"]="$input"
    fi
}

# ── Derive Qt6_DIR from a platform root ──────────────────────────────────────
derive_qt6_dir() {
    local root="$1"
    if [ -n "$root" ]; then
        RESULT["Qt6_DIR"]="${root}/lib/cmake/Qt6"
    fi
}

# ── Start ────────────────────────────────────────────────────────────────────
printf "\n${BOLD}QtQuickTemplate — Developer Environment Configuration${RESET}\n"
printf "Detected platform: ${CYAN}%s${RESET}\n" "$PLATFORM"
printf "Values are written to ${CYAN}.env.local${RESET} (gitignored).\n"
printf "Press Enter to keep the default shown in [brackets].\n"

# ── Qt SDK Paths ─────────────────────────────────────────────────────────────
header "Qt SDK Paths"

case "$PLATFORM" in
    Darwin)
        prompt QT_MACOS_ROOT  "macOS Qt SDK root (e.g. ~/Qt/6.10.2/macos)"
        prompt QT_IOS_ROOT    "iOS Qt SDK root (e.g. ~/Qt/6.10.2/ios)"
        prompt QT_ANDROID_ROOT "Android Qt SDK root (e.g. ~/Qt/6.10.2/android_arm64_v8a)"
        prompt QT_HOST_ROOT    "Host Qt root for cross-compilation (e.g. ~/Qt/6.10.2/macos)"
        # Derive Qt6_DIR from macOS root
        derive_qt6_dir "${RESULT[QT_MACOS_ROOT]:-${DEFAULTS[QT_MACOS_ROOT]:-}}"
        ;;
    Linux)
        prompt QT_LINUX_ROOT  "Linux Qt SDK root (e.g. ~/Qt/6.10.2/gcc_64)"
        prompt QT_ANDROID_ROOT "Android Qt SDK root (leave empty to skip)"
        prompt QT_HOST_ROOT    "Host Qt root for cross-compilation (leave empty to skip)"
        # Derive Qt6_DIR from Linux root
        derive_qt6_dir "${RESULT[QT_LINUX_ROOT]:-${DEFAULTS[QT_LINUX_ROOT]:-}}"
        ;;
    *)
        # Generic fallback
        prompt QT_ROOT "Qt SDK root"
        derive_qt6_dir "${RESULT[QT_ROOT]:-${DEFAULTS[QT_ROOT]:-}}"
        ;;
esac

# Show derived Qt6_DIR
if [ -n "${RESULT[Qt6_DIR]:-}" ]; then
    info "Derived Qt6_DIR=${RESULT[Qt6_DIR]}"
fi

# ── Apple Code Signing (macOS only) ──────────────────────────────────────────
if [ "$PLATFORM" = "Darwin" ]; then
    header "Apple Code Signing"
    prompt APPLE_DEVELOPMENT_TEAM         "Apple Development Team ID (10-char)"
    prompt MACOS_APP_SIGN_IDENTITY        "macOS app signing identity (e.g. Developer ID Application: ...)"
    prompt MACOS_DMG_SIGN_IDENTITY        "macOS DMG signing identity (e.g. Developer ID Application: ...)"
    prompt MACOS_NOTARY_KEYCHAIN_PROFILE  "macOS notarization keychain profile name"
    prompt MACOS_APP_STORE_PROVISIONING_PROFILE "macOS App Store provisioning profile name (leave empty to skip)"

    header "App Store Connect"
    prompt ASC_API_KEY_ID    "App Store Connect API Key ID"
    prompt ASC_API_ISSUER_ID "App Store Connect Issuer ID"

    header "iOS Signing"
    prompt IOS_PROVISIONING_PROFILE "iOS provisioning profile name (leave empty to skip)"
fi

# ── Android Signing ──────────────────────────────────────────────────────────
if [ -n "${RESULT[QT_ANDROID_ROOT]:-${DEFAULTS[QT_ANDROID_ROOT]:-}}" ]; then
    header "Android Signing"
    prompt ANDROID_KEYSTORE_PATH     "Keystore file path"
    prompt ANDROID_KEYSTORE_PASSWORD "Keystore password"
    prompt ANDROID_KEY_ALIAS         "Key alias"
    prompt ANDROID_KEY_PASSWORD      "Key password"

    header "Google Play Upload"
    prompt ANDROID_PLAY_SERVICE_ACCOUNT_FILE "Play Console service account JSON path (leave empty to skip)"
fi

# ── Linux Signing ────────────────────────────────────────────────────────────
if [ "$PLATFORM" = "Linux" ]; then
    header "Linux AppImage Signing"
    prompt GPG_KEY_ID "GPG key ID for AppImage signing (leave empty to skip)"
fi

# ── Write .env.local ─────────────────────────────────────────────────────────
header "Writing .env.local"

{
    echo "# Generated by tools/configure-env.sh on $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "# Re-run the script to update. Manual edits are preserved as defaults."
    echo ""

    # Qt SDK Paths
    local_has_qt=false
    for var in QT_MACOS_ROOT QT_IOS_ROOT QT_LINUX_ROOT QT_ANDROID_ROOT QT_HOST_ROOT QT_ROOT Qt6_DIR; do
        if [ -n "${RESULT[$var]:-}" ]; then
            if [ "$local_has_qt" = false ]; then
                echo "# Qt SDK Paths"
                local_has_qt=true
            fi
            echo "${var}=${RESULT[$var]}"
        fi
    done
    [ "$local_has_qt" = true ] && echo ""

    # Apple Signing
    local_has_apple=false
    for var in APPLE_DEVELOPMENT_TEAM MACOS_APP_SIGN_IDENTITY MACOS_DMG_SIGN_IDENTITY MACOS_NOTARY_KEYCHAIN_PROFILE MACOS_APP_STORE_PROVISIONING_PROFILE ASC_API_KEY_ID ASC_API_ISSUER_ID IOS_PROVISIONING_PROFILE; do
        if [ -n "${RESULT[$var]:-}" ]; then
            if [ "$local_has_apple" = false ]; then
                echo "# Apple Signing"
                local_has_apple=true
            fi
            echo "${var}=${RESULT[$var]}"
        fi
    done
    [ "$local_has_apple" = true ] && echo ""

    # Android Signing
    local_has_android=false
    for var in ANDROID_KEYSTORE_PATH ANDROID_KEYSTORE_PASSWORD ANDROID_KEY_ALIAS ANDROID_KEY_PASSWORD ANDROID_PLAY_SERVICE_ACCOUNT_FILE; do
        if [ -n "${RESULT[$var]:-}" ]; then
            if [ "$local_has_android" = false ]; then
                echo "# Android Signing"
                local_has_android=true
            fi
            echo "${var}=${RESULT[$var]}"
        fi
    done
    [ "$local_has_android" = true ] && echo ""

    # Linux Signing
    if [ -n "${RESULT[GPG_KEY_ID]:-}" ]; then
        echo "# Linux Signing"
        echo "GPG_KEY_ID=${RESULT[GPG_KEY_ID]}"
        echo ""
    fi
} > "$ENV_LOCAL"

ok "Wrote $ENV_LOCAL"
printf "\nYou can now run builds with ${CYAN}./tools/run${RESET}:\n"
printf "  ./tools/run cmake --preset <preset>        # configure\n"
printf "  ./tools/run cmake --build --preset <preset> # build\n"
