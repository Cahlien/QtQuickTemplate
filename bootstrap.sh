#!/usr/bin/env bash
# bootstrap.sh — one-command dev environment setup for QtQuickTemplate
# Installs uv (if needed), downloads the pinned Python, and syncs all dependencies.
# Idempotent — safe to re-run at any time.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── Colors (skip if not a terminal) ──────────────────────────────────────────
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
if ! command -v uv &>/dev/null; then
    info "uv not found — installing..."
    curl -LsSf https://astral.sh/uv/install.sh | sh

    # The installer adds uv to ~/.local/bin (or ~/.cargo/bin on some systems).
    # Source the env script if it exists, otherwise add common paths.
    if [ -f "$HOME/.local/bin/env" ]; then
        # shellcheck disable=SC1091
        . "$HOME/.local/bin/env"
    elif [ -f "$HOME/.cargo/env" ]; then
        # shellcheck disable=SC1091
        . "$HOME/.cargo/env"
    else
        export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
    fi

    if ! command -v uv &>/dev/null; then
        echo "ERROR: uv installed but not found on PATH. Open a new terminal and re-run." >&2
        exit 1
    fi
    ok "uv installed: $(uv --version)"
else
    ok "uv already installed: $(uv --version)"
fi

# ── Step 2: Install the pinned Python ────────────────────────────────────────
info "Ensuring pinned Python is available (.python-version → $(cat .python-version))..."
uv python install
ok "Python ready: $(uv run python --version)"

# ── Step 3: Sync dependencies (creates/updates .venv/) ──────────────────────
info "Syncing dependencies..."
uv sync
ok "Virtual environment ready at .venv/"

# ── Step 4: Verify key tools ────────────────────────────────────────────────
info "Verifying tools..."
uv run cmake   --version | head -1
uv run conan   --version | head -1
uv run pytest  --version | head -1
ok "All tools verified."

# ── Done ─────────────────────────────────────────────────────────────────────
printf "\n${BOLD}Bootstrap complete!${RESET}\n"
printf "Run commands through the venv with ${CYAN}uv run${RESET}:\n"
printf "  uv run cmake --preset <preset>        # configure\n"
printf "  uv run cmake --build --preset <preset> # build\n"
printf "  uv run conan install .                 # install C++ deps\n"
printf "  uv run pytest                          # run tests\n"
printf "\nOr activate the venv directly:\n"
printf "  source .venv/bin/activate\n"
