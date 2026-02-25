#!/usr/bin/env python3
"""Configure the Qt Quick Template project with a new package identifier."""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import NamedTuple

# ---------------------------------------------------------------------------
# Old (template) constants — hardcoded current values
# ---------------------------------------------------------------------------
OLD_PACKAGE = "dev.crowell.qtquicktemplate"
OLD_DOMAIN = "dev.crowell"
OLD_APP_CAMEL = "QtQuickTemplate"
OLD_APP_LOWER = "qtquicktemplate"
OLD_APP_UPPER = "QTQUICKTEMPLATE"
OLD_DOMAIN_PATH = "dev/crowell"
OLD_PACKAGE_PATH = "dev/crowell/qtquicktemplate"
OLD_PACKAGE_NS = "dev::crowell::qtquicktemplate"
OLD_PACKAGE_UNDERSCORE = "dev_crowell_qtquicktemplate"

# ---------------------------------------------------------------------------
# Skip rules
# ---------------------------------------------------------------------------
SKIP_DIRS = {".git", ".venv", "tools", "node_modules", "__pycache__"}
SKIP_DIR_PREFIXES = ("build", "cmake-build-")

BINARY_EXTENSIONS = {
    ".png", ".svg", ".ico", ".icns", ".jpg", ".jpeg", ".gif", ".webp",
    ".woff", ".woff2", ".ttf", ".otf",
    ".jar", ".aar", ".class", ".dex",
    ".so", ".dylib", ".a", ".o",
    ".AppImage", ".apk", ".aab", ".ipa", ".dmg", ".pkg",
    ".zip", ".tar", ".gz", ".bz2", ".xz", ".7z",
    ".lock", ".p8",
}

SKIP_FILENAMES = {"configure_package.py"}

# ---------------------------------------------------------------------------
# Data types
# ---------------------------------------------------------------------------

class PackageIdentity(NamedTuple):
    package: str            # com.example.myapp
    domain: str             # com.example
    app_camel: str          # MyApp  (preserved from user input)
    app_lower: str          # myapp
    app_upper: str          # MYAPP
    domain_path: str        # com/example
    package_path: str       # com/example/myapp
    package_ns: str         # com::example::myapp
    package_underscore: str # com_example_myapp


# ---------------------------------------------------------------------------
# Input parsing & validation
# ---------------------------------------------------------------------------
_SEGMENT_RE = re.compile(r"^[a-zA-Z][a-zA-Z0-9]*$")


def parse_package(raw: str) -> PackageIdentity:
    """Parse and validate a dotted package name into all derived forms."""
    segments = raw.split(".")
    if len(segments) < 2:
        raise ValueError(f"Package name needs at least 2 segments (got {raw!r})")

    for seg in segments:
        if not _SEGMENT_RE.match(seg):
            raise ValueError(
                f"Segment {seg!r} is invalid — must match [a-zA-Z][a-zA-Z0-9]*"
            )

    app_camel = segments[-1]          # preserved as-is
    domain_parts = [s.lower() for s in segments[:-1]]
    app_lower = app_camel.lower()
    app_upper = app_camel.upper()

    domain = ".".join(domain_parts)
    package = f"{domain}.{app_lower}"
    domain_path = "/".join(domain_parts)
    package_path = f"{domain_path}/{app_lower}"
    package_ns = "::".join(domain_parts + [app_lower])
    package_underscore = "_".join(domain_parts + [app_lower])

    return PackageIdentity(
        package=package,
        domain=domain,
        app_camel=app_camel,
        app_lower=app_lower,
        app_upper=app_upper,
        domain_path=domain_path,
        package_path=package_path,
        package_ns=package_ns,
        package_underscore=package_underscore,
    )


# ---------------------------------------------------------------------------
# Replacement table (longest-first order)
# ---------------------------------------------------------------------------

def build_replacements(new: PackageIdentity) -> list[tuple[str, str]]:
    """Return an ordered list of (old, new) string replacements.

    Entries are sorted longest-first so that more-specific patterns are
    replaced before shorter ones that could partially match.
    """
    return [
        # 1  JNI mangled prefix
        (f"Java_{OLD_PACKAGE_UNDERSCORE}", f"Java_{new.package_underscore}"),
        # 2  C++ namespace with sub-namespace
        (f"{OLD_PACKAGE_NS}::navigation", f"{new.package_ns}::navigation"),
        # 3  C++ namespace
        (OLD_PACKAGE_NS, new.package_ns),
        # 4  Java/Kotlin sub-package: activities
        (f"{OLD_PACKAGE}.activities", f"{new.package}.activities"),
        # 5  Java/Kotlin sub-package: extensions
        (f"{OLD_PACKAGE}.extensions", f"{new.package}.extensions"),
        # 6  Android resource import
        (f"{OLD_PACKAGE}.R", f"{new.package}.R"),
        # 7  Windows manifest
        (f"{OLD_DOMAIN}.app.{OLD_APP_CAMEL}", f"{new.domain}.app.{new.app_camel}"),
        # 8  QML module URI (main app)
        (f"{OLD_DOMAIN}.{OLD_APP_CAMEL}", f"{new.domain}.{new.app_camel}"),
        # 9  QML module URI (AppTheme)
        (f"{OLD_DOMAIN}.AppTheme", f"{new.domain}.AppTheme"),
        # 10 QML module URI (AppStyle)
        (f"{OLD_DOMAIN}.AppStyle", f"{new.domain}.AppStyle"),
        # 11 Full package dotted (Android/Apple/Linux ID)
        (OLD_PACKAGE, new.package),
        # 11b Bare domain dotted (catches `dev.crowell.${PROJECT_NAME}` etc.)
        (OLD_DOMAIN, new.domain),
        # 12 QRC resource path (CamelCase app)
        (f"{OLD_DOMAIN_PATH}/{OLD_APP_CAMEL}", f"{new.domain_path}/{new.app_camel}"),
        # 13 JNI class path
        (OLD_PACKAGE_PATH, new.package_path),
        # 14 QML output dir (AppTheme)
        (f"{OLD_DOMAIN_PATH}/AppTheme", f"{new.domain_path}/AppTheme"),
        # 15 QML output dir (AppStyle)
        (f"{OLD_DOMAIN_PATH}/AppStyle", f"{new.domain_path}/AppStyle"),
        # 15b Bare domain path (catches `dev/crowell/${PROJECT_NAME}` etc.)
        (OLD_DOMAIN_PATH, new.domain_path),
        # 16 CMake cache variable prefix
        (f"{OLD_APP_UPPER}_", f"{new.app_upper}_"),
        # 17 Conan recipe class name
        (f"{OLD_APP_CAMEL}Recipe", f"{new.app_camel}Recipe"),
        # 18 CMake project name / display name
        (OLD_APP_CAMEL, new.app_camel),
        # 19 Lowercase name (pyproject, conan)
        (OLD_APP_LOWER, new.app_lower),
    ]


# ---------------------------------------------------------------------------
# File discovery
# ---------------------------------------------------------------------------

def project_files(root: Path) -> list[Path]:
    """Return all text files in the project tree that should be processed."""
    result: list[Path] = []
    for dirpath, dirnames, filenames in os.walk(root):
        # Prune skipped directories in-place so os.walk won't descend
        dirnames[:] = [
            d for d in dirnames
            if d not in SKIP_DIRS
            and not d.startswith(SKIP_DIR_PREFIXES)
        ]

        for fname in filenames:
            if fname in SKIP_FILENAMES:
                continue
            p = Path(dirpath) / fname
            if p.suffix.lower() in BINARY_EXTENSIONS:
                continue
            result.append(p)
    return result


# ---------------------------------------------------------------------------
# Directory / file renames
# ---------------------------------------------------------------------------

def rename_android_kotlin_tree(
    root: Path,
    new: PackageIdentity,
) -> list[str]:
    """Move the Android Kotlin source tree to the new package path.

    Returns a list of human-readable descriptions of actions taken.
    """
    actions: list[str] = []

    base = root / "platforms" / "android" / "src" / "main" / "kotlin"
    old_dir = base / OLD_PACKAGE_PATH.replace("/", os.sep)
    new_dir = base / new.package_path.replace("/", os.sep)

    if not old_dir.exists():
        return actions

    if old_dir == new_dir:
        return actions

    # Create new parent directories
    new_dir.mkdir(parents=True, exist_ok=True)

    # Move each child (activities/, extensions/, loose files)
    for child in list(old_dir.iterdir()):
        dest = new_dir / child.name
        shutil.move(str(child), str(dest))
        actions.append(f"  moved {child.relative_to(root)} -> {dest.relative_to(root)}")

    # Remove empty old directories walking upward to `base`
    cursor = old_dir
    while cursor != base:
        try:
            cursor.rmdir()  # only succeeds if empty
            actions.append(f"  removed empty dir {cursor.relative_to(root)}")
        except OSError:
            break
        cursor = cursor.parent

    return actions


def rename_files(root: Path, new: PackageIdentity) -> list[str]:
    """Rename individual platform/config files. Returns action descriptions."""
    actions: list[str] = []
    renames = [
        (
            root / "platforms" / "linux" / f"{OLD_PACKAGE}.metainfo.xml.in",
            root / "platforms" / "linux" / f"{new.package}.metainfo.xml.in",
        ),
        (
            root / "platforms" / "macos" / f"{OLD_APP_CAMEL}.entitlements",
            root / "platforms" / "macos" / f"{new.app_camel}.entitlements",
        ),
        (
            root / "platforms" / "linux" / f"{OLD_APP_CAMEL}.desktop.in",
            root / "platforms" / "linux" / f"{new.app_camel}.desktop.in",
        ),
        (
            root / "doc" / f"{OLD_APP_LOWER}.qdocconf",
            root / "doc" / f"{new.app_lower}.qdocconf",
        ),
    ]

    for old_path, new_path in renames:
        if not old_path.exists():
            continue
        if old_path == new_path:
            continue
        new_path.parent.mkdir(parents=True, exist_ok=True)
        old_path.rename(new_path)
        actions.append(
            f"  renamed {old_path.relative_to(root)} -> {new_path.relative_to(root)}"
        )

    return actions


# ---------------------------------------------------------------------------
# Content replacement
# ---------------------------------------------------------------------------

def replace_in_file(
    path: Path,
    replacements: list[tuple[str, str]],
) -> bool:
    """Apply ordered replacements to a single file. Returns True if changed."""
    try:
        text = path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, PermissionError):
        return False

    original = text
    for old, new in replacements:
        text = text.replace(old, new)

    if text == original:
        return False

    path.write_text(text, encoding="utf-8")
    return True


# ---------------------------------------------------------------------------
# Git status check
# ---------------------------------------------------------------------------

def check_git_clean(root: Path) -> bool:
    """Return True if the working tree is clean. Prints a warning if dirty."""
    try:
        result = subprocess.run(
            ["git", "status", "--porcelain"],
            cwd=root,
            capture_output=True,
            text=True,
            check=True,
        )
        if result.stdout.strip():
            print("WARNING: Working tree has uncommitted changes.")
            print("         Commit or stash before running this script")
            print("         so you can easily revert if something goes wrong.")
            return False
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        # Not a git repo or git not installed — skip the check
        return True


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Rename the Qt Quick Template package identifier throughout the project.",
    )
    parser.add_argument(
        "package",
        help=(
            "New package name in dot notation (e.g., com.example.MyApp). "
            "The last segment's casing is preserved for display names."
        ),
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Skip the git clean check.",
    )
    args = parser.parse_args()

    # 1. Validate input
    try:
        new = parse_package(args.package)
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    root = Path(__file__).resolve().parent.parent  # tools/ -> project root

    # 2. Git status check
    if not args.force:
        if not check_git_clean(root):
            print("\nUse --force to skip this check.")
            return 1

    # 3. Print mapping table
    print("\n=== Package Rename Configuration ===\n")
    print(f"  Package (dotted):    {OLD_PACKAGE}  ->  {new.package}")
    print(f"  Domain:              {OLD_DOMAIN}  ->  {new.domain}")
    print(f"  App name (CamelCase):{OLD_APP_CAMEL}  ->  {new.app_camel}")
    print(f"  App name (lower):    {OLD_APP_LOWER}  ->  {new.app_lower}")
    print(f"  App name (UPPER):    {OLD_APP_UPPER}  ->  {new.app_upper}")
    print(f"  Namespace:           {OLD_PACKAGE_NS}  ->  {new.package_ns}")
    print(f"  Path:                {OLD_PACKAGE_PATH}  ->  {new.package_path}")
    print(f"  Underscore:          {OLD_PACKAGE_UNDERSCORE}  ->  {new.package_underscore}")
    print()

    # 4. Rename Android Kotlin directory tree
    print("--- Renaming Android Kotlin directory tree ---")
    kotlin_actions = rename_android_kotlin_tree(root, new)
    if kotlin_actions:
        for action in kotlin_actions:
            print(action)
    else:
        print("  (no changes needed)")

    # 5. Rename individual files
    print("\n--- Renaming platform/config files ---")
    file_actions = rename_files(root, new)
    if file_actions:
        for action in file_actions:
            print(action)
    else:
        print("  (no changes needed)")

    # 6. Apply content replacements to all text files
    print("\n--- Applying content replacements ---")
    replacements = build_replacements(new)
    files = project_files(root)
    modified_count = 0
    for fpath in files:
        if replace_in_file(fpath, replacements):
            modified_count += 1
            print(f"  modified {fpath.relative_to(root)}")

    # 7. Summary
    print(f"\n=== Summary ===")
    print(f"  Files modified:   {modified_count}")
    print(f"  Files renamed:    {len(file_actions)}")
    print(f"  Dirs moved:       {len(kotlin_actions)}")

    # 8. Post-run instructions
    print("\n=== Next Steps ===")
    print("  1. Update the display name \"QtQuick Template\" in:")
    print("       qml/Main.qml  (window title)")
    print("       platforms/linux/*.desktop.in  (Name, GenericName, Comment)")
    print("       platforms/linux/*.metainfo.xml.in  (name, summary, description)")
    print("       platforms/windows/app.rc.in  (FileDescription, ProductName)")
    print("  2. Run  ./tools/uv lock  to regenerate the lockfile")
    print("  3. Delete all build directories:  rm -rf build/ cmake-build-*/")
    print("  4. Reconfigure and build to verify everything works")
    print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
