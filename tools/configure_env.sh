#!/usr/bin/env bash
# tools/configure_env.sh — interactive wizard that writes .env.local
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

info()  { printf "${CYAN}[configure_env]${RESET} %s\n" "$*"; }
ok()    { printf "${GREEN}[configure_env]${RESET} %s\n" "$*"; }
warn()  { printf "${YELLOW}[configure_env]${RESET} %s\n" "$*"; }
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

# ── Derive Qt6_DIR and CMAKE_PREFIX_PATH from a platform root ────────────────
derive_qt_paths() {
    local root="$1"
    if [ -n "$root" ]; then
        RESULT["Qt6_DIR"]="${root}/lib/cmake/Qt6"
        RESULT["CMAKE_PREFIX_PATH"]="$root"
    fi
}

# ── Auto-detect Android SDK/NDK from common locations ────────────────────────
detect_android_sdk() {
    local candidates=()
    case "$PLATFORM" in
        Darwin)
            candidates=(
                "$HOME/Library/Android/sdk"
                "$HOME/Android/Sdk"
            )
            ;;
        Linux)
            candidates=(
                "$HOME/Android/Sdk"
                "/opt/android-sdk"
                "$HOME/android-sdk"
            )
            ;;
    esac
    for dir in "${candidates[@]}"; do
        if [ -d "$dir" ]; then
            echo "$dir"
            return
        fi
    done
}

detect_android_ndk() {
    local sdk_root="${1:-}"
    if [ -n "$sdk_root" ] && [ -d "$sdk_root/ndk" ]; then
        # Pick the highest-versioned NDK directory
        local latest
        latest=$(ls -1d "$sdk_root/ndk"/*/ 2>/dev/null | sort -V | tail -1)
        if [ -n "$latest" ]; then
            echo "${latest%/}"
            return
        fi
    fi
}

detect_java_home() {
    case "$PLATFORM" in
        Darwin)
            if /usr/libexec/java_home &>/dev/null; then
                /usr/libexec/java_home 2>/dev/null
                return
            fi
            ;;
        Linux)
            local candidates=(
                "/usr/lib/jvm/java-17-openjdk"
                "/usr/lib/jvm/java-17-openjdk-amd64"
                "/usr/lib/jvm/java-21-openjdk"
                "/usr/lib/jvm/java-21-openjdk-amd64"
            )
            for dir in "${candidates[@]}"; do
                if [ -d "$dir" ]; then
                    echo "$dir"
                    return
                fi
            done
            # Fallback: follow the java binary
            if command -v java &>/dev/null; then
                local java_bin
                java_bin="$(readlink -f "$(command -v java)")"
                echo "${java_bin%/bin/java}"
                return
            fi
            ;;
    esac
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
        # Derive Qt6_DIR and CMAKE_PREFIX_PATH from macOS root
        derive_qt_paths "${RESULT[QT_MACOS_ROOT]:-${DEFAULTS[QT_MACOS_ROOT]:-}}"
        ;;
    Linux)
        prompt QT_LINUX_ROOT  "Linux Qt SDK root (e.g. ~/Qt/6.10.2/gcc_64)"
        prompt QT_ANDROID_ROOT "Android Qt SDK root (leave empty to skip)"
        prompt QT_HOST_ROOT    "Host Qt root for cross-compilation (leave empty to skip)"
        # Derive Qt6_DIR and CMAKE_PREFIX_PATH from Linux root
        derive_qt_paths "${RESULT[QT_LINUX_ROOT]:-${DEFAULTS[QT_LINUX_ROOT]:-}}"
        ;;
    *)
        # Generic fallback
        prompt QT_ROOT "Qt SDK root"
        derive_qt_paths "${RESULT[QT_ROOT]:-${DEFAULTS[QT_ROOT]:-}}"
        ;;
esac

# Show derived paths
if [ -n "${RESULT[Qt6_DIR]:-}" ]; then
    info "Derived Qt6_DIR=${RESULT[Qt6_DIR]}"
fi
if [ -n "${RESULT[CMAKE_PREFIX_PATH]:-}" ]; then
    info "Derived CMAKE_PREFIX_PATH=${RESULT[CMAKE_PREFIX_PATH]}"
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

# ── Android SDK & Signing ───────────────────────────────────────────────────
if [ -n "${RESULT[QT_ANDROID_ROOT]:-${DEFAULTS[QT_ANDROID_ROOT]:-}}" ]; then
    header "Android SDK"

    # Auto-detect defaults for Android toolchain paths
    detected_sdk="$(detect_android_sdk || true)"
    prompt ANDROID_SDK_ROOT "Android SDK root" "${DEFAULTS[ANDROID_SDK_ROOT]:-$detected_sdk}"

    detected_ndk="$(detect_android_ndk "${RESULT[ANDROID_SDK_ROOT]:-${DEFAULTS[ANDROID_SDK_ROOT]:-}}" || true)"
    prompt ANDROID_NDK_ROOT "Android NDK root" "${DEFAULTS[ANDROID_NDK_ROOT]:-$detected_ndk}"

    detected_java="$(detect_java_home || true)"
    prompt JAVA_HOME "Java JDK home (JDK 17+ recommended)" "${DEFAULTS[JAVA_HOME]:-$detected_java}"

    header "Android Signing"
    prompt ANDROID_KEYSTORE_PATH     "Keystore file path"
    prompt ANDROID_KEYSTORE_PASSWORD "Keystore password"
    prompt ANDROID_KEY_ALIAS         "Key alias"
    prompt ANDROID_KEY_PASSWORD      "Key password"

    header "Google Play Upload"
    prompt ANDROID_PLAY_SERVICE_ACCOUNT_FILE "Play Console service account JSON path (leave empty to skip)"
    prompt ANDROID_PLAY_TRACK                "Play Console release track" "${DEFAULTS[ANDROID_PLAY_TRACK]:-internal}"
    prompt ANDROID_PLAY_RELEASE_STATUS       "Play Console release status" "${DEFAULTS[ANDROID_PLAY_RELEASE_STATUS]:-completed}"
fi

# ── Linux Signing ────────────────────────────────────────────────────────────
if [ "$PLATFORM" = "Linux" ]; then
    header "Linux AppImage Signing"
    prompt GPG_KEY_ID "GPG key ID for AppImage signing (leave empty to skip)"
fi

# ── Write .env.local ─────────────────────────────────────────────────────────
header "Writing .env.local"

{
    echo "# Generated by tools/configure_env.sh on $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "# Re-run the script to update. Manual edits are preserved as defaults."
    echo ""

    # Qt SDK Paths
    has_qt=false
    for var in QT_MACOS_ROOT QT_IOS_ROOT QT_LINUX_ROOT QT_ANDROID_ROOT QT_HOST_ROOT QT_ROOT Qt6_DIR CMAKE_PREFIX_PATH; do
        if [ -n "${RESULT[$var]:-}" ]; then
            if [ "$has_qt" = false ]; then
                echo "# Qt SDK Paths"
                has_qt=true
            fi
            echo "${var}=${RESULT[$var]}"
        fi
    done
    [ "$has_qt" = true ] && echo ""

    # Apple Signing
    has_apple=false
    for var in APPLE_DEVELOPMENT_TEAM MACOS_APP_SIGN_IDENTITY MACOS_DMG_SIGN_IDENTITY MACOS_NOTARY_KEYCHAIN_PROFILE MACOS_APP_STORE_PROVISIONING_PROFILE ASC_API_KEY_ID ASC_API_ISSUER_ID IOS_PROVISIONING_PROFILE; do
        if [ -n "${RESULT[$var]:-}" ]; then
            if [ "$has_apple" = false ]; then
                echo "# Apple Signing"
                has_apple=true
            fi
            echo "${var}=${RESULT[$var]}"
        fi
    done
    [ "$has_apple" = true ] && echo ""

    # Android SDK
    has_android_sdk=false
    for var in ANDROID_SDK_ROOT ANDROID_NDK_ROOT JAVA_HOME; do
        if [ -n "${RESULT[$var]:-}" ]; then
            if [ "$has_android_sdk" = false ]; then
                echo "# Android SDK"
                has_android_sdk=true
            fi
            echo "${var}=${RESULT[$var]}"
        fi
    done
    [ "$has_android_sdk" = true ] && echo ""

    # Android Signing
    has_android_signing=false
    for var in ANDROID_KEYSTORE_PATH ANDROID_KEYSTORE_PASSWORD ANDROID_KEY_ALIAS ANDROID_KEY_PASSWORD; do
        if [ -n "${RESULT[$var]:-}" ]; then
            if [ "$has_android_signing" = false ]; then
                echo "# Android Signing"
                has_android_signing=true
            fi
            echo "${var}=${RESULT[$var]}"
        fi
    done
    [ "$has_android_signing" = true ] && echo ""

    # Android Play Upload
    has_play=false
    for var in ANDROID_PLAY_SERVICE_ACCOUNT_FILE ANDROID_PLAY_TRACK ANDROID_PLAY_RELEASE_STATUS; do
        if [ -n "${RESULT[$var]:-}" ]; then
            if [ "$has_play" = false ]; then
                echo "# Google Play Upload"
                has_play=true
            fi
            echo "${var}=${RESULT[$var]}"
        fi
    done
    [ "$has_play" = true ] && echo ""

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
