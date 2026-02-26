"""Terminal UI helpers: color output and interactive prompting."""

from __future__ import annotations

import sys
from pathlib import Path

from configure_env._types import EnvVar


class ColorOutput:
    """ANSI color helper gated on *use_color*."""

    _TAG = "configure_env"

    def __init__(self, use_color: bool) -> None:
        if use_color:
            self._bold = "\033[1m"
            self._green = "\033[0;32m"
            self._cyan = "\033[0;36m"
            self._yellow = "\033[0;33m"
            self._reset = "\033[0m"
        else:
            self._bold = self._green = self._cyan = self._yellow = self._reset = ""

    def info(self, msg: str) -> None:
        print(f"{self._cyan}[{self._TAG}]{self._reset} {msg}")

    def ok(self, msg: str) -> None:
        print(f"{self._green}[{self._TAG}]{self._reset} {msg}")

    def warn(self, msg: str) -> None:
        print(f"{self._yellow}[{self._TAG}]{self._reset} {msg}")

    def header(self, heading: str) -> None:
        print(f"\n{self._bold}── {heading} ──{self._reset}")

    def banner(self, title: str) -> None:
        print(f"\n{self._bold}{title}{self._reset}")

    def cyan(self, text: str) -> str:
        return f"{self._cyan}{text}{self._reset}"


def prompt_var(
    var: EnvVar,
    defaults: dict[str, str],
    result: dict[str, str],
    out: ColorOutput,
) -> None:
    """Prompt the user for a single variable and store the value in *result*."""
    default = var.default or defaults.get(var.name, "")

    if default:
        prompt_str = f"  {var.description} ({var.name}) [{default}]: "
    else:
        prompt_str = f"  {var.description} ({var.name}): "

    try:
        value = input(prompt_str)
    except EOFError:
        value = ""

    value = value.strip() or default

    if value and var.is_path:
        if not Path(value).exists():
            out.warn(f"    Path does not exist yet: {value} (continuing anyway)")

    if value:
        result[var.name] = value
