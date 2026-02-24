#!/usr/bin/env bash
# bootstrap.sh — one-command dev environment setup for QtQuickTemplate
# Installs uv into tools/ (if needed), downloads the pinned Python, and syncs
# all dependencies. Idempotent — safe to re-run at any time.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

UV="$SCRIPT_DIR/tools/uv"

# ── Terminal colors ───────────────────────────────────────────────────────────
if [ -t 1 ]; then
    BOLD='\033[1m'
    GREEN='\033[0;32m'
    CYAN='\033[0;36m'
    RESET='\033[0m'
else
    BOLD='' GREEN='' CYAN='' RESET=''
fi

info()  { printf "${CYAN}[bootstrap]${RESET} %s\n" "$*"; }
ok()    { printf "${GREEN}[bootstrap]${RESET} %s\n" "$*"; }

# ── Step 1: Ensure uv is installed ───────────────────────────────────────────
if [ ! -x "$UV" ]; then
    info "uv not found in tools/ — installing..."
    mkdir -p "$SCRIPT_DIR/tools"
    curl -LsSf https://astral.sh/uv/install.sh | UV_UNMANAGED_INSTALL="$SCRIPT_DIR/tools" sh

    if [ ! -x "$UV" ]; then
        echo "ERROR: uv installed but not found at $UV." >&2
        exit 1
    fi
    ok "uv installed: $("$UV" --version)"
else
    ok "uv already installed: $("$UV" --version)"
fi

# ── Step 2: Install the pinned Python ────────────────────────────────────────
info "Ensuring pinned Python is available (.python-version → $(cat .python-version))..."
"$UV" python install
ok "Python ready: $("$UV" run python --version)"

# ── Step 3: Sync dependencies (creates/updates .venv/) ──────────────────────
info "Syncing dependencies..."
"$UV" sync
ok "Virtual environment ready at .venv/"

# ── Step 4: Verify key tools ────────────────────────────────────────────────
info "Verifying tools..."
"$UV" run cmake   --version | head -1
"$UV" run conan   --version | head -1
"$UV" run pytest  --version | head -1
ok "All tools verified."

# ── Step 5 (Linux): Install linuxdeploy AppImage toolchain ─────────────────
if [ "$(uname -s)" = "Linux" ]; then
    case "$(uname -m)" in
        x86_64)  LD_ARCH=x86_64; LDAI_ARCH=x86_64 ;;
        i?86)    LD_ARCH=i386;   LDAI_ARCH=i686   ;;
        aarch64) LD_ARCH=aarch64; LDAI_ARCH=aarch64 ;;
        armv7l)  LD_ARCH=armhf;  LDAI_ARCH=armhf  ;;
        *)       LD_ARCH="" ;;
    esac

    if [ -n "$LD_ARCH" ]; then
        info "Installing linuxdeploy toolchain for $LD_ARCH..."
        _ld_files=(
            "linuxdeploy/continuous/linuxdeploy-${LD_ARCH}.AppImage"
            "linuxdeploy-plugin-qt/continuous/linuxdeploy-plugin-qt-${LD_ARCH}.AppImage"
            "linuxdeploy-plugin-appimage/continuous/linuxdeploy-plugin-appimage-${LDAI_ARCH}.AppImage"
        )
        for _entry in "${_ld_files[@]}"; do
            _repo="${_entry%%/*}"
            _file="${_entry##*/}"
            _dest="$SCRIPT_DIR/tools/$_file"
            if [ ! -x "$_dest" ]; then
                info "Downloading $_file..."
                curl -Lo "$_dest" "https://github.com/linuxdeploy/${_repo}/releases/download/${_entry#*/}"
                chmod +x "$_dest"
                ok "Installed $_file"
            else
                ok "$_file already installed"
            fi
        done
    else
        info "No linuxdeploy builds for $(uname -m) — skipping"
    fi
fi

# ── Step 6: Install bundletool (Android AAB/APK tooling) ───────────────────
BUNDLETOOL_VERSION="1.18.3"
BUNDLETOOL_JAR="$SCRIPT_DIR/tools/bundletool-all-${BUNDLETOOL_VERSION}.jar"
if [ ! -f "$BUNDLETOOL_JAR" ]; then
    info "Downloading bundletool ${BUNDLETOOL_VERSION}..."
    curl -Lo "$BUNDLETOOL_JAR" \
        "https://github.com/google/bundletool/releases/download/${BUNDLETOOL_VERSION}/bundletool-all-${BUNDLETOOL_VERSION}.jar"
    ok "Installed bundletool ${BUNDLETOOL_VERSION}"
else
    ok "bundletool ${BUNDLETOOL_VERSION} already installed"
fi

# ── Done ─────────────────────────────────────────────────────────────────────
printf "\n${BOLD}Bootstrap complete!${RESET}\n"
printf "Run commands through the venv with ${CYAN}./tools/uv run${RESET}:\n"
printf "  ./tools/uv run cmake --preset <preset>        # configure\n"
printf "  ./tools/uv run cmake --build --preset <preset> # build\n"
printf "  ./tools/uv run conan install .                 # install C++ deps\n"
printf "  ./tools/uv run pytest                          # run tests\n"
printf "\nOr activate the venv directly:\n"
printf "  source .venv/bin/activate\n"
