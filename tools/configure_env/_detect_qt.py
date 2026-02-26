"""Qt SDK autodetection for all platforms."""

from __future__ import annotations

import re
from pathlib import Path

from configure_env._types import Platform

_VERSION_RE = re.compile(r"^(\d+)\.(\d+)(?:\.(\d+))?$")


def detect_qt_base(home: Path, plat: Platform) -> Path | None:
    """Return the Qt SDK base directory (e.g. ``~/Qt``) or *None*."""
    candidates: list[Path] = [
        home / "Qt",
        home / "Qt6",
    ]
    if plat == Platform.WINDOWS:
        candidates.append(Path("C:/Qt"))
    else:
        candidates.extend([Path("/opt/Qt"), Path("/usr/local/Qt")])

    for d in candidates:
        if d.is_dir():
            return d
    return None


def detect_qt_version_dir(base: Path) -> Path | None:
    """Return the latest ``X.Y.Z`` subdirectory inside *base*, or *None*."""
    best: tuple[tuple[int, ...], Path] | None = None
    try:
        children = list(base.iterdir())
    except OSError:
        return None

    for child in children:
        if not child.is_dir():
            continue
        m = _VERSION_RE.match(child.name)
        if not m:
            continue
        ver = (int(m.group(1)), int(m.group(2)), int(m.group(3) or 0))
        if best is None or ver > best[0]:
            best = (ver, child)

    return best[1] if best else None


def detect_qt_platform_root(
    subdir: str,
    home: Path,
    plat: Platform,
) -> str:
    """Return ``<base>/<version>/<subdir>`` if it exists, else ``""``."""
    base = detect_qt_base(home, plat)
    if base is None:
        return ""
    ver_dir = detect_qt_version_dir(base)
    if ver_dir is None:
        return ""
    candidate = ver_dir / subdir
    if candidate.is_dir():
        return str(candidate)
    return ""
