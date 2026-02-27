"""Wrappers around codesign, spctl, and stapler for verification."""

from __future__ import annotations

import re
import subprocess
from pathlib import Path


def codesign_verify(
    path: Path,
    *,
    deep: bool = False,
    strict: bool = False,
) -> tuple[bool, str]:
    """Run ``codesign --verify`` and return *(success, combined_output)*."""
    cmd = ["codesign", "--verify", "--verbose=2"]
    if deep:
        cmd.append("--deep")
    if strict:
        cmd.append("--strict")
    cmd.append(str(path))
    result = subprocess.run(cmd, capture_output=True, text=True)
    output = (result.stdout + "\n" + result.stderr).strip()
    return result.returncode == 0, output


def codesign_display(path: Path) -> tuple[bool, str]:
    """Run ``codesign -dv --verbose=4`` and return *(success, combined_output)*."""
    result = subprocess.run(
        ["codesign", "-dv", "--verbose=4", str(path)],
        capture_output=True,
        text=True,
    )
    output = (result.stdout + "\n" + result.stderr).strip()
    return result.returncode == 0, output


def parse_codesign_authority(output: str) -> str | None:
    """Extract the first ``Authority=`` value from codesign output."""
    match = re.search(r"^Authority=(.+)$", output, re.MULTILINE)
    return match.group(1).strip() if match else None


def parse_codesign_team_id(output: str) -> str | None:
    """Extract ``TeamIdentifier=`` from codesign output."""
    match = re.search(r"^TeamIdentifier=(.+)$", output, re.MULTILINE)
    return match.group(1).strip() if match else None


def spctl_assess(
    path: Path,
    artifact_type: str,
) -> tuple[bool, str]:
    """Run Gatekeeper assessment.

    *artifact_type* should be ``"execute"`` for app bundles or
    ``"install"`` for packages/DMGs.

    Returns *(success, combined_output)*.  "Insufficient Context" from
    ``spctl`` is treated as a pass (known harmless with notarized DMGs).
    """
    result = subprocess.run(
        ["spctl", "--assess", "--type", artifact_type, "-vv", str(path)],
        capture_output=True,
        text=True,
    )
    output = (result.stdout + "\n" + result.stderr).strip()
    success = result.returncode == 0 or "Insufficient Context" in output
    return success, output


def stapler_validate(path: Path) -> tuple[bool, str]:
    """Run ``xcrun stapler validate`` and return *(success, combined_output)*."""
    result = subprocess.run(
        ["xcrun", "stapler", "validate", str(path)],
        capture_output=True,
        text=True,
    )
    output = (result.stdout + "\n" + result.stderr).strip()
    return result.returncode == 0, output
