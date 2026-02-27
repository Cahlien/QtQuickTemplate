"""Artifact path resolution for all three Apple deploy pipelines.

Paths mirror the conventions in the CMake deploy modules under
``cmake/deploy/{ios,macos,apple}/``.
"""

from __future__ import annotations

import re
from pathlib import Path


# ---------------------------------------------------------------------------
# Version xcconfig parsing
# ---------------------------------------------------------------------------

def parse_version_xcconfig(path: Path) -> dict[str, str]:
    """Parse a ``version.xcconfig`` file into a dict.

    Expected format::

        MARKETING_VERSION = 1.0
        CURRENT_PROJECT_VERSION = 1.0.0.42
    """
    result: dict[str, str] = {}
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("//"):
            continue
        match = re.match(r"^(\w+)\s*=\s*(.+)$", line)
        if match:
            result[match.group(1)] = match.group(2).strip()
    return result


# ---------------------------------------------------------------------------
# iOS artifacts
# ---------------------------------------------------------------------------

def ios_version_xcconfig(build_dir: Path) -> Path:
    """``<build_dir>/ios/version.xcconfig``"""
    return build_dir / "ios" / "version.xcconfig"


def ios_archive_path(build_dir: Path, project_name: str = "QtQuickTemplate") -> Path:
    """``<build_dir>/ios/<project>.xcarchive``"""
    return build_dir / "ios" / f"{project_name}.xcarchive"


def ios_archive_app_path(
    build_dir: Path,
    project_name: str = "QtQuickTemplate",
) -> Path:
    """App bundle inside the iOS xcarchive."""
    return (
        ios_archive_path(build_dir, project_name)
        / "Products"
        / "Applications"
        / f"{project_name}.app"
    )


def ios_export_dir(build_dir: Path) -> Path:
    """``<build_dir>/ios/export``"""
    return build_dir / "ios" / "export"


def ios_ipa_path(build_dir: Path) -> Path | None:
    """Return the first ``.ipa`` in the iOS export directory, or ``None``."""
    export = ios_export_dir(build_dir)
    if not export.is_dir():
        return None
    ipas = sorted(export.glob("*.ipa"))
    return ipas[-1] if ipas else None


# ---------------------------------------------------------------------------
# macOS DMG artifacts
# ---------------------------------------------------------------------------

def macos_app_bundle_path(
    build_dir: Path,
    project_name: str = "QtQuickTemplate",
) -> Path:
    """``<build_dir>/<project>.app``"""
    return build_dir / f"{project_name}.app"


def macos_dmg_path(
    build_dir: Path,
    version: str,
    project_name: str = "QtQuickTemplate",
) -> Path:
    """``<build_dir>/<project>-<version>-macOS.dmg``"""
    return build_dir / f"{project_name}-{version}-macOS.dmg"


def macos_dmg_glob(
    build_dir: Path,
    project_name: str = "QtQuickTemplate",
) -> Path | None:
    """Find a DMG via glob (useful when exact version isn't known)."""
    dmgs = sorted(build_dir.glob(f"{project_name}-*-macOS.dmg"))
    return dmgs[-1] if dmgs else None


# ---------------------------------------------------------------------------
# macOS App Store artifacts
# ---------------------------------------------------------------------------

def macos_appstore_version_xcconfig(build_dir: Path) -> Path:
    """``<build_dir>/macos/version.xcconfig``"""
    return build_dir / "macos" / "version.xcconfig"


def macos_appstore_archive_path(
    build_dir: Path,
    project_name: str = "QtQuickTemplate",
) -> Path:
    """``<build_dir>/macos/<project>.xcarchive``"""
    return build_dir / "macos" / f"{project_name}.xcarchive"


def macos_appstore_archive_app_path(
    build_dir: Path,
    project_name: str = "QtQuickTemplate",
) -> Path:
    """App bundle inside the macOS App Store xcarchive."""
    return (
        macos_appstore_archive_path(build_dir, project_name)
        / "Products"
        / "Applications"
        / f"{project_name}.app"
    )


def macos_appstore_export_dir(build_dir: Path) -> Path:
    """``<build_dir>/macos/export``"""
    return build_dir / "macos" / "export"


def macos_pkg_path(build_dir: Path) -> Path | None:
    """Return the first ``.pkg`` in the macOS export directory, or ``None``."""
    export = macos_appstore_export_dir(build_dir)
    if not export.is_dir():
        return None
    pkgs = sorted(export.glob("*.pkg"))
    return pkgs[-1] if pkgs else None
