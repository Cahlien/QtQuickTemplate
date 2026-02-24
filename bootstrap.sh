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

# ── Done ─────────────────────────────────────────────────────────────────────
printf "\n${BOLD}Bootstrap complete!${RESET}\n"
printf "Run commands through the venv with ${CYAN}./tools/uv run${RESET}:\n"
printf "  ./tools/uv run cmake --preset <preset>        # configure\n"
printf "  ./tools/uv run cmake --build --preset <preset> # build\n"
printf "  ./tools/uv run conan install .                 # install C++ deps\n"
printf "  ./tools/uv run pytest                          # run tests\n"
printf "\nOr activate the venv directly:\n"
printf "  source .venv/bin/activate\n"
