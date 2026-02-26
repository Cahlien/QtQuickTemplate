"""Orchestrator: drives the interactive configure_env wizard."""

from __future__ import annotations

from pathlib import Path

from configure_env._defaults import load_defaults
from configure_env._emit import emit_env_local
from configure_env._platform import detect_platform, home_dir, is_tty
from configure_env._prompt import ColorOutput, prompt_var
from configure_env._sections import (
    build_android_qt_section,
    build_android_sdk_sections,
    build_apple_sections,
    build_emit_sections,
    build_host_root_var,
    build_linux_signing_section,
    build_qt_sdk_section,
    derive_defaults,
    has_android_qt,
)
from configure_env._types import Section


def _prompt_section(
    section: Section,
    defaults: dict[str, str],
    result: dict[str, str],
    out: ColorOutput,
) -> None:
    out.header(section.heading)
    for var in section.variables:
        prompt_var(var, defaults, result, out)


def main() -> int:
    plat = detect_platform()
    home = home_dir()
    out = ColorOutput(is_tty())

    project_root = Path(__file__).resolve().parent.parent.parent
    env_local = project_root / ".env.local"

    defaults = load_defaults(env_local)
    if defaults:
        out.info("Loading existing .env.local for defaults...")

    out.banner("QtQuickTemplate — Developer Environment Configuration")
    print(f"Detected platform: {out.cyan(plat.value)}")
    print(f"Values are written to {out.cyan('.env.local')} (gitignored).")
    print("Press Enter to accept the detected value in [brackets], or type to override.")

    result: dict[str, str] = {}

    qt_section = build_qt_sdk_section(plat, home, defaults)
    _prompt_section(qt_section, defaults, result, out)

    host_var = build_host_root_var(plat, result, defaults)
    prompt_var(host_var, defaults, result, out)

    derive_defaults(plat, result, defaults)
    if result.get("Qt6_DIR"):
        out.info(f"Derived Qt6_DIR={result['Qt6_DIR']}")
    if result.get("CMAKE_PREFIX_PATH"):
        out.info(f"Derived CMAKE_PREFIX_PATH={result['CMAKE_PREFIX_PATH']}")

    android_qt = build_android_qt_section(plat, home, defaults)
    out.header(android_qt.heading)
    print("  Paths are detected from your Qt installation. Leave empty to exclude an ABI.")
    for var in android_qt.variables:
        prompt_var(var, defaults, result, out)

    if plat == plat.DARWIN:
        for section in build_apple_sections(defaults):
            _prompt_section(section, defaults, result, out)

    if has_android_qt(result, defaults):
        for section in build_android_sdk_sections(plat, home, defaults, result):
            _prompt_section(section, defaults, result, out)

    if plat == plat.LINUX:
        linux_section = build_linux_signing_section(defaults)
        _prompt_section(linux_section, defaults, result, out)

    out.header("Writing .env.local")
    emit_sections = build_emit_sections(plat, result, defaults)
    emit_env_local(env_local, emit_sections, result)
    out.ok(f"Wrote {env_local}")

    run_cmd = "./tools/run" if plat != plat.WINDOWS else r".\tools\run.ps1"
    print(f"\nYou can now run builds with {out.cyan(run_cmd)}:")
    print(f"  {run_cmd} cmake --preset <preset>        # configure")
    print(f"  {run_cmd} cmake --build --preset <preset> # build")

    return 0
