"""CMake configure and build invocation helpers."""

from __future__ import annotations

import subprocess
from pathlib import Path


def run_cmake_configure(
    preset: str,
    source_dir: Path,
    *,
    timeout: int = 300,
) -> subprocess.CompletedProcess[str]:
    """Run ``cmake --preset <preset>`` in *source_dir*."""
    return subprocess.run(
        ["cmake", "--preset", preset],
        cwd=source_dir,
        capture_output=True,
        text=True,
        timeout=timeout,
    )


def run_cmake_build(
    preset: str,
    source_dir: Path,
    *,
    timeout: int = 1800,
) -> subprocess.CompletedProcess[str]:
    """Run ``cmake --build --preset <preset>`` in *source_dir*."""
    return subprocess.run(
        ["cmake", "--build", "--preset", preset],
        cwd=source_dir,
        capture_output=True,
        text=True,
        timeout=timeout,
    )


def run_cmake_build_target(
    build_dir: Path,
    target: str,
    *,
    config: str = "Release",
    timeout: int = 1800,
) -> subprocess.CompletedProcess[str]:
    """Run ``cmake --build <build_dir> --target <target> --config <config>``."""
    return subprocess.run(
        [
            "cmake",
            "--build",
            str(build_dir),
            "--target",
            target,
            "--config",
            config,
        ],
        capture_output=True,
        text=True,
        timeout=timeout,
    )
