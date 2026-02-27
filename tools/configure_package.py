#!/usr/bin/env python3
"""Configure the Qt Quick Template project with a new package identifier."""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import tomllib
from pathlib import Path
from typing import NamedTuple

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


def read_current_identity(root: Path) -> str:
    """Read the current package identity from devcro.toml.

    Reconstructs a dotted package string with CamelCase app name so that
    ``parse_package()`` derives the correct ``app_camel`` field.
    """
    devcro_path = root / "devcro.toml"
    with open(devcro_path, "rb") as f:
        data = tomllib.load(f)
    package_name = data["config"]["package_name"]   # e.g. dev.crowell.qtquicktemplate
    app_name = data["application"]["name"]           # e.g. QtQuickTemplate
    segments = package_name.split(".")
    segments[-1] = app_name  # preserve CamelCase for parse_package()
    return ".".join(segments)                        # e.g. dev.crowell.QtQuickTemplate


# ---------------------------------------------------------------------------
# Replacement table (longest-first order)
# ---------------------------------------------------------------------------

def build_replacements(old: PackageIdentity, new: PackageIdentity) -> list[tuple[str, str]]:
    """Return an ordered list of (old, new) string replacements.

    Entries are sorted longest-first so that more-specific patterns are
    replaced before shorter ones that could partially match.
    """
    return [
        # 1  JNI mangled prefix
        (f"Java_{old.package_underscore}", f"Java_{new.package_underscore}"),
        # 2  C++ namespace with sub-namespace
        (f"{old.package_ns}::navigation", f"{new.package_ns}::navigation"),
        # 3  C++ namespace
        (old.package_ns, new.package_ns),
        # 4  Java/Kotlin sub-package: activities
        (f"{old.package}.activities", f"{new.package}.activities"),
        # 5  Java/Kotlin sub-package: extensions
        (f"{old.package}.extensions", f"{new.package}.extensions"),
        # 6  Android resource import
        (f"{old.package}.R", f"{new.package}.R"),
        # 7  Windows manifest
        (f"{old.domain}.app.{old.app_camel}", f"{new.domain}.app.{new.app_camel}"),
        # 8  QML module URI (main app)
        (f"{old.domain}.{old.app_camel}", f"{new.domain}.{new.app_camel}"),
        # 9  QML module URI (AppTheme)
        (f"{old.domain}.AppTheme", f"{new.domain}.AppTheme"),
        # 10 QML module URI (AppStyle)
        (f"{old.domain}.AppStyle", f"{new.domain}.AppStyle"),
        # 11 Full package dotted (Android/Apple/Linux ID)
        (old.package, new.package),
        # 11b Bare domain dotted (catches `dev.crowell.${PROJECT_NAME}` etc.)
        (old.domain, new.domain),
        # 12 QRC resource path (CamelCase app)
        (f"{old.domain_path}/{old.app_camel}", f"{new.domain_path}/{new.app_camel}"),
        # 13 JNI class path
        (old.package_path, new.package_path),
        # 14 QML output dir (AppTheme)
        (f"{old.domain_path}/AppTheme", f"{new.domain_path}/AppTheme"),
        # 15 QML output dir (AppStyle)
        (f"{old.domain_path}/AppStyle", f"{new.domain_path}/AppStyle"),
        # 15b Bare domain path (catches `dev/crowell/${PROJECT_NAME}` etc.)
        (old.domain_path, new.domain_path),
        # 16 CMake cache variable prefix
        (f"{old.app_upper}_", f"{new.app_upper}_"),
        # 17 Conan recipe class name
        (f"{old.app_camel}Recipe", f"{new.app_camel}Recipe"),
        # 18 CMake project name / display name
        (old.app_camel, new.app_camel),
        # 19 Lowercase name (pyproject, conan)
        (old.app_lower, new.app_lower),
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
    old: PackageIdentity,
    new: PackageIdentity,
) -> list[str]:
    """Move the Android Kotlin source tree to the new package path.

    Returns a list of human-readable descriptions of actions taken.
    """
    actions: list[str] = []

    base = root / "app" / "platforms" / "android" / "src" / "main" / "kotlin"
    old_dir = base / old.package_path.replace("/", os.sep)
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


def rename_files(root: Path, old: PackageIdentity, new: PackageIdentity) -> list[str]:
    """Rename individual platform/config files. Returns action descriptions."""
    actions: list[str] = []
    renames = [
        (
            root / "app" / "platforms" / "linux" / f"{old.package}.metainfo.xml.in",
            root / "app" / "platforms" / "linux" / f"{new.package}.metainfo.xml.in",
        ),
        (
            root / "app" / "platforms" / "macos" / f"{old.app_camel}.entitlements",
            root / "app" / "platforms" / "macos" / f"{new.app_camel}.entitlements",
        ),
        (
            root / "app" / "platforms" / "linux" / f"{old.app_camel}.desktop.in",
            root / "app" / "platforms" / "linux" / f"{new.app_camel}.desktop.in",
        ),
        (
            root / "app" / "doc" / f"{old.app_lower}.qdocconf",
            root / "app" / "doc" / f"{new.app_lower}.qdocconf",
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

    # 2. Read current identity from devcro.toml
    try:
        current_id = read_current_identity(root)
        old = parse_package(current_id)
    except (FileNotFoundError, KeyError, ValueError) as exc:
        print(f"ERROR: Cannot read current identity from devcro.toml: {exc}", file=sys.stderr)
        return 1

    # 3. Git status check
    if not args.force:
        if not check_git_clean(root):
            print("\nUse --force to skip this check.")
            return 1

    # 4. Print mapping table
    print("\n=== Package Rename Configuration ===\n")
    print(f"  Package (dotted):    {old.package}  ->  {new.package}")
    print(f"  Domain:              {old.domain}  ->  {new.domain}")
    print(f"  App name (CamelCase):{old.app_camel}  ->  {new.app_camel}")
    print(f"  App name (lower):    {old.app_lower}  ->  {new.app_lower}")
    print(f"  App name (UPPER):    {old.app_upper}  ->  {new.app_upper}")
    print(f"  Namespace:           {old.package_ns}  ->  {new.package_ns}")
    print(f"  Path:                {old.package_path}  ->  {new.package_path}")
    print(f"  Underscore:          {old.package_underscore}  ->  {new.package_underscore}")
    print()

    # 5. Rename Android Kotlin directory tree
    print("--- Renaming Android Kotlin directory tree ---")
    kotlin_actions = rename_android_kotlin_tree(root, old, new)
    if kotlin_actions:
        for action in kotlin_actions:
            print(action)
    else:
        print("  (no changes needed)")

    # 6. Rename individual files
    print("\n--- Renaming platform/config files ---")
    file_actions = rename_files(root, old, new)
    if file_actions:
        for action in file_actions:
            print(action)
    else:
        print("  (no changes needed)")

    # 7. Apply content replacements to all text files
    print("\n--- Applying content replacements ---")
    replacements = build_replacements(old, new)
    files = project_files(root)
    modified_count = 0
    for fpath in files:
        if replace_in_file(fpath, replacements):
            modified_count += 1
            print(f"  modified {fpath.relative_to(root)}")

    # 8. Summary
    print(f"\n=== Summary ===")
    print(f"  Files modified:   {modified_count}")
    print(f"  Files renamed:    {len(file_actions)}")
    print(f"  Dirs moved:       {len(kotlin_actions)}")

    # 9. Post-run instructions
    print("\n=== Next Steps ===")
    print("  1. Update the display name \"QtQuick Template\" in:")
    print("       app/qml/Main.qml  (window title)")
    print("       app/platforms/linux/*.desktop.in  (Name, GenericName, Comment)")
    print("       app/platforms/linux/*.metainfo.xml.in  (name, summary, description)")
    print("       app/platforms/windows/app.rc.in  (FileDescription, ProductName)")
    print("  2. Run  ./tools/uv lock  to regenerate the lockfile")
    print("  3. Delete all build directories:  rm -rf build/ cmake-build-*/")
    print("  4. Reconfigure and build to verify everything works")
    print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
