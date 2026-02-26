"""Shared data types for the configure_env wizard."""

from __future__ import annotations

import enum
from typing import NamedTuple


class Platform(enum.Enum):
    DARWIN = "Darwin"
    LINUX = "Linux"
    WINDOWS = "Windows"


class EnvVar(NamedTuple):
    """A single environment variable to prompt the user for."""

    name: str
    description: str
    default: str = ""
    is_path: bool = False


class Section(NamedTuple):
    """A group of environment variables with a display heading."""

    heading: str
    variables: list[EnvVar]
