#!/usr/bin/env python3
"""First-time project setup and version/name propagation orchestrator.

Reads ``devcro.toml`` to decide whether the project needs initial
configuration (interactive prompts for name, package, version) or just
version and name propagation across all version-bearing and
name-bearing files.

The ``name`` field in devcro.toml is the human-readable application
name (e.g. "QtQuick Template").  The CamelCase identifier used by
CMake, Conan, and file names is derived by stripping spaces.

Usage::

    python tools/devcro.py            # interactive first-time setup
    python tools/devcro.py --yes      # accept devcro.toml defaults (CI)
"""

from __future__ import annotations

import argparse
import glob
import re
import subprocess
import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEVCRO_TOML = ROOT / "devcro.toml"

# Ensure tools/ is on sys.path so we can import configure_package helpers
_TOOLS_DIR = str(ROOT / "tools")
if _TOOLS_DIR not in sys.path:
    sys.path.insert(0, _TOOLS_DIR)

from configure_package import project_files, replace_in_file  # noqa: E402

TEMPLATE_DEFAULT_PACKAGE = "dev.crowell.qtquicktemplate"
TEMPLATE_DEFAULT_NAME = "QtQuick Template"


# ---------------------------------------------------------------------------
# devcro.toml helpers
# ---------------------------------------------------------------------------

def load_devcro() -> dict:
    with open(DEVCRO_TOML, "rb") as f:
        return tomllib.load(f)


def update_devcro_toml(
    *,
    name: str | None = None,
    version: str | None = None,
    package_name: str | None = None,
    bootstrapped: bool | None = None,
) -> None:
    """Update specific fields in devcro.toml via regex replacement."""
    text = DEVCRO_TOML.read_text(encoding="utf-8")

    if name is not None:
        text = re.sub(
            r'^(name\s*=\s*)"[^"]*"',
            rf'\g<1>"{name}"',
            text,
            count=1,
            flags=re.MULTILINE,
        )

    if version is not None:
        text = re.sub(
            r'^(version\s*=\s*)"[^"]*"',
            rf'\g<1>"{version}"',
            text,
            count=1,
            flags=re.MULTILINE,
        )

    if package_name is not None:
        text = re.sub(
            r'^(package_name\s*=\s*)"[^"]*"',
            rf'\g<1>"{package_name}"',
            text,
            count=1,
            flags=re.MULTILINE,
        )

    if bootstrapped is not None:
        text = re.sub(
            r'^(bootstrapped\s*=\s*)\S+',
            rf'\g<1>{"true" if bootstrapped else "false"}',
            text,
            count=1,
            flags=re.MULTILINE,
        )

    DEVCRO_TOML.write_text(text, encoding="utf-8")


# ---------------------------------------------------------------------------
# Interactive prompts
# ---------------------------------------------------------------------------

def prompt_value(label: str, default: str) -> str:
    """Prompt the user for a value with a default."""
    result = input(f"  {label} [{default}]: ").strip()
    return result if result else default


# ---------------------------------------------------------------------------
# Version propagation
# ---------------------------------------------------------------------------

VERSION_TARGETS: list[tuple[str, str]] = [
    # (relative glob, regex pattern with one capture group before version)
    # app/CMakeLists.txt reads version from devcro.toml at configure time
    ("app/conanfile.py",         r'(version\s*=\s*")[^"]*"'),
    ("conanfile.py",             r'(version\s*=\s*")[^"]*"'),
    ("pyproject.toml",           r'(version\s*=\s*")[^"]*"'),
]


def discover_lib_conanfiles() -> list[str]:
    """Find all app/libs/*/conanfile.py files."""
    pattern = str(ROOT / "app" / "libs" / "*" / "conanfile.py")
    return sorted(glob.glob(pattern))


def propagate_version(version: str) -> int:
    """Propagate version to all version-bearing files. Returns count of changed files."""
    changed = 0

    # Static targets
    for rel_path, pattern in VERSION_TARGETS:
        fpath = ROOT / rel_path
        if not fpath.exists():
            continue
        text = fpath.read_text(encoding="utf-8")
        # The pattern captures everything before the version; we replace the
        # version portion while keeping the prefix.
        new_text = re.sub(pattern, rf'\g<1>{version}"', text, count=1)
        if new_text != text:
            fpath.write_text(new_text, encoding="utf-8")
            changed += 1
            print(f"  updated version in {rel_path}")

    # Dynamic targets: lib conanfiles
    lib_pattern = r'(version\s*=\s*")[^"]*"'
    for lib_path in discover_lib_conanfiles():
        fpath = Path(lib_path)
        text = fpath.read_text(encoding="utf-8")
        new_text = re.sub(lib_pattern, rf'\g<1>{version}"', text, count=1)
        if new_text != text:
            fpath.write_text(new_text, encoding="utf-8")
            changed += 1
            rel = fpath.relative_to(ROOT)
            print(f"  updated version in {rel}")

    return changed


# ---------------------------------------------------------------------------
# Name propagation
# ---------------------------------------------------------------------------

def propagate_name(old_name: str, new_name: str) -> int:
    """Replace old_name with new_name across all project files.

    Returns count of changed files.
    """
    if old_name == new_name:
        return 0

    replacements = [(old_name, new_name)]
    files = project_files(ROOT)
    changed = 0
    for fpath in files:
        if replace_in_file(fpath, replacements):
            changed += 1
            rel = fpath.relative_to(ROOT)
            print(f"  updated name in {rel}")
    return changed


# ---------------------------------------------------------------------------
# Main logic
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Project setup orchestrator — first-time configuration and version propagation.",
    )
    parser.add_argument(
        "--yes", "--defaults",
        action="store_true",
        dest="yes",
        help="Accept devcro.toml values as-is (non-interactive mode).",
    )
    args = parser.parse_args()

    data = load_devcro()
    bootstrapped = data["config"]["bootstrapped"]

    if not bootstrapped:
        # ── First-time setup ──────────────────────────────────────────────
        current_name = data["application"]["name"]
        current_version = data["application"]["version"]
        current_package = data["config"]["package_name"]

        if args.yes:
            app_name = current_name
            version = current_version
            package = current_package
        else:
            print("\n=== Project Configuration ===\n")
            print("  Configure your project identity. Press Enter to keep defaults.\n")
            app_name = prompt_value("Application name", current_name)
            package = prompt_value("Package name (e.g. com.example.myapp)", current_package)
            version = prompt_value("Version", current_version)
            print()

        # Derive CamelCase identifier from the human-readable name
        app_camel = app_name.replace(" ", "")

        # Run configure_package.py if the package changed from template default
        if package != current_package:
            # Reconstruct CamelCase package for configure_package.py
            segments = package.split(".")
            segments[-1] = app_camel
            full_package = ".".join(segments)

            print(f"--- Renaming package: {current_package} -> {package} ---")
            result = subprocess.run(
                [sys.executable, str(ROOT / "tools" / "configure_package.py"), full_package, "--force"],
                cwd=ROOT,
            )
            if result.returncode != 0:
                print("ERROR: configure_package.py failed.", file=sys.stderr)
                return 1

        # Propagate name (human-readable form) across project files
        old_name = TEMPLATE_DEFAULT_NAME if package != current_package else current_name
        print("--- Propagating application name ---")
        name_changed = propagate_name(old_name, app_name)
        if name_changed == 0:
            print("  (all files already at target name)")

        # Propagate version
        print("--- Propagating version ---")
        changed = propagate_version(version)
        if changed == 0:
            print("  (all files already at target version)")

        # Update devcro.toml
        update_devcro_toml(
            name=app_name,
            version=version,
            package_name=package,
            bootstrapped=True,
        )
        print(f"\nProject configured: {app_name} ({package}) v{version}")
        print("devcro.toml updated with bootstrapped = true")

    else:
        # ── Already bootstrapped — version propagation ────────────────────
        version = data["application"]["version"]
        app_name = data["application"]["name"]

        print(f"--- Application: {app_name} ---")

        print("--- Checking version propagation ---")
        changed = propagate_version(version)
        if changed == 0:
            print("  (all files in sync)")
        else:
            print(f"  propagated version {version} to {changed} file(s)")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
