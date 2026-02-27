"""Host platform detection helpers."""

from __future__ import annotations

import platform
import sys
from pathlib import Path

from configure_env._types import Platform


def detect_platform() -> Platform:
    name = platform.system()
    if name == "Darwin":
        return Platform.DARWIN
    if name == "Windows":
        return Platform.WINDOWS
    return Platform.LINUX


def home_dir() -> Path:
    return Path.home()


def is_tty() -> bool:
    return hasattr(sys.stdout, "isatty") and sys.stdout.isatty()
