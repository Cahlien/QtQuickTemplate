"""Parse an existing .env.local file into a defaults dict."""

from __future__ import annotations

from pathlib import Path


def load_defaults(path: Path) -> dict[str, str]:
    """Read *path* and return ``{KEY: value}`` for every non-comment line."""
    defaults: dict[str, str] = {}
    if not path.is_file():
        return defaults
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        eq = stripped.find("=")
        if eq > 0:
            defaults[stripped[:eq]] = stripped[eq + 1 :]
    return defaults
