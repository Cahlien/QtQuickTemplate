#!/usr/bin/env bash
# bootstrap.sh — one-command dev environment setup for QtQuickTemplate
# Installs uv into tools/ (if needed), downloads the pinned Python, and syncs
# all dependencies. Idempotent — safe to re-run at any time.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

UV="$SCRIPT_DIR/uv"

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
    curl -LsSf https://astral.sh/uv/install.sh | UV_UNMANAGED_INSTALL="$SCRIPT_DIR" sh

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

# The cmake pip package bundles native binaries that may lack the execute bit
# on some platforms (observed with freethreaded Python 3.14t on Linux).
chmod +x "$PROJECT_ROOT"/.venv/lib/python*/site-packages/cmake/data/bin/* 2>/dev/null || true

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
            _dest="$SCRIPT_DIR/$_file"
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
BUNDLETOOL_JAR="$SCRIPT_DIR/bundletool-all-${BUNDLETOOL_VERSION}.jar"
if [ ! -f "$BUNDLETOOL_JAR" ]; then
    info "Downloading bundletool ${BUNDLETOOL_VERSION}..."
    curl -Lo "$BUNDLETOOL_JAR" \
        "https://github.com/google/bundletool/releases/download/${BUNDLETOOL_VERSION}/bundletool-all-${BUNDLETOOL_VERSION}.jar"
    ok "Installed bundletool ${BUNDLETOOL_VERSION}"
else
    ok "bundletool ${BUNDLETOOL_VERSION} already installed"
fi

# ── Step 7: Project configuration (devcro.py) ────────────────────────────────
info "Running project configuration..."
"$UV" run python tools/devcro.py "$@"
ok "Project configuration complete."

# ── Step 8: Developer environment (.env.local) ───────────────────────────────
info "Configuring developer environment..."
"$UV" run python tools/configure_env.py
ok "Developer environment configured."

# ── Done ─────────────────────────────────────────────────────────────────────
printf "\n${BOLD}Bootstrap complete!${RESET}\n"

printf "Run commands through the env-aware wrapper with ${CYAN}./tools/run${RESET}:\n"
printf "  ./tools/run cmake --preset <preset>        # configure\n"
printf "  ./tools/run cmake --build --preset <preset> # build\n"
printf "  ./tools/run conan install .                 # install C++ deps\n"
printf "  ./tools/run pytest                          # run tests\n"
printf "\nOr activate the venv directly:\n"
printf "  source .venv/bin/activate\n"
