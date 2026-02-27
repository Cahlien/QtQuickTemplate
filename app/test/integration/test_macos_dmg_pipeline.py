"""macOS DMG (direct distribution) deploy pipeline integration tests.

Pipeline chain:
    MacDeployQt → DMG → NotarizeMacOS → VerifyMacOSPackage
"""

from __future__ import annotations

from pathlib import Path

import pytest

from integration.helpers.artifacts import (
    macos_app_bundle_path,
    macos_dmg_glob,
    macos_dmg_path,
)
from integration.helpers.codesign import (
    codesign_display,
    codesign_verify,
    parse_codesign_authority,
    spctl_assess,
    stapler_validate,
)

pytestmark = [pytest.mark.macos_dmg]


# ---------------------------------------------------------------------------
# MacDeployQt — app bundle verification
# ---------------------------------------------------------------------------

class TestMacOSAppBundle:
    """Verify the app bundle produced by ``MacDeployQt``."""

    def test_app_bundle_exists(self, macos_dmg_build_dir: Path) -> None:
        """App bundle must exist after MacDeployQt."""
        app = macos_app_bundle_path(macos_dmg_build_dir)
        assert app.is_dir(), f"App bundle not found at {app}"

    def test_has_qt_frameworks(self, macos_dmg_build_dir: Path) -> None:
        """App bundle must contain deployed Qt frameworks."""
        app = macos_app_bundle_path(macos_dmg_build_dir)
        frameworks = app / "Contents" / "Frameworks"
        assert frameworks.is_dir(), "Frameworks directory missing from app bundle"
        qt_frameworks = list(frameworks.glob("Qt*.framework"))
        assert len(qt_frameworks) > 0, "No Qt frameworks found in app bundle"

    def test_has_qml_plugins(self, macos_dmg_build_dir: Path) -> None:
        """App bundle must contain a PlugIns directory."""
        app = macos_app_bundle_path(macos_dmg_build_dir)
        plugins = app / "Contents" / "PlugIns"
        assert plugins.is_dir(), "PlugIns directory missing from app bundle"

    def test_codesign_valid(self, macos_dmg_build_dir: Path) -> None:
        """App bundle must pass deep strict codesign verification."""
        app = macos_app_bundle_path(macos_dmg_build_dir)
        ok, output = codesign_verify(app, deep=True, strict=True)
        assert ok, f"App bundle codesign invalid:\n{output}"

    def test_signed_with_developer_id(self, macos_dmg_build_dir: Path) -> None:
        """App bundle must be signed with a Developer ID Application identity."""
        app = macos_app_bundle_path(macos_dmg_build_dir)
        ok, output = codesign_display(app)
        assert ok
        authority = parse_codesign_authority(output)
        assert authority and authority.startswith("Developer ID Application"), (
            f"Expected 'Developer ID Application' signing, got: {authority}"
        )

    def test_gatekeeper_passes(self, macos_dmg_build_dir: Path) -> None:
        """App bundle must pass Gatekeeper assessment."""
        app = macos_app_bundle_path(macos_dmg_build_dir)
        ok, output = spctl_assess(app, "execute")
        assert ok, f"Gatekeeper rejected app bundle:\n{output}"


# ---------------------------------------------------------------------------
# DMG packaging
# ---------------------------------------------------------------------------

class TestMacOSDmg:
    """Verify the ``DMG`` target output."""

    def test_dmg_exists(self, macos_dmg_build_dir: Path, project_version: str | None) -> None:
        """DMG file must exist after the DMG target."""
        if project_version:
            dmg = macos_dmg_path(macos_dmg_build_dir, project_version)
        else:
            dmg = macos_dmg_glob(macos_dmg_build_dir)
        assert dmg is not None and dmg.is_file(), "DMG not found"

    def test_dmg_size(self, macos_dmg_build_dir: Path) -> None:
        """DMG must be larger than 1 MB."""
        dmg = macos_dmg_glob(macos_dmg_build_dir)
        assert dmg is not None, "DMG not found"
        size_mb = dmg.stat().st_size / (1024 * 1024)
        assert size_mb > 1, f"DMG suspiciously small: {size_mb:.1f} MB"

    def test_dmg_codesign_valid(self, macos_dmg_build_dir: Path) -> None:
        """DMG must pass codesign verification."""
        dmg = macos_dmg_glob(macos_dmg_build_dir)
        assert dmg is not None
        ok, output = codesign_verify(dmg)
        assert ok, f"DMG codesign invalid:\n{output}"

    def test_dmg_gatekeeper_passes(self, macos_dmg_build_dir: Path) -> None:
        """DMG must pass Gatekeeper assessment."""
        dmg = macos_dmg_glob(macos_dmg_build_dir)
        assert dmg is not None
        ok, output = spctl_assess(dmg, "install")
        assert ok, f"Gatekeeper rejected DMG:\n{output}"


# ---------------------------------------------------------------------------
# Notarization
# ---------------------------------------------------------------------------

@pytest.mark.requires_notarization
class TestMacOSNotarization:
    """Verify ``NotarizeMacOS`` target results (stapled tickets)."""

    def test_dmg_stapler_valid(self, macos_dmg_build_dir: Path) -> None:
        """DMG must have a valid notarization staple."""
        dmg = macos_dmg_glob(macos_dmg_build_dir)
        assert dmg is not None
        ok, output = stapler_validate(dmg)
        assert ok, f"DMG stapler validation failed:\n{output}"

    def test_app_stapler_valid(self, macos_dmg_build_dir: Path) -> None:
        """App bundle must have a valid notarization staple."""
        app = macos_app_bundle_path(macos_dmg_build_dir)
        ok, output = stapler_validate(app)
        assert ok, f"App stapler validation failed:\n{output}"


# ---------------------------------------------------------------------------
# Full verification — parity with VerifyMacOSPackage CMake target
# ---------------------------------------------------------------------------

class TestMacOSFullVerification:
    """All six checks from ``VerifyMacOSPackage`` target in one test."""

    @pytest.mark.requires_notarization
    def test_verify_all(self, macos_dmg_build_dir: Path) -> None:
        """Run all six verification checks from VerifyMacOSPackage in one pass."""
        app = macos_app_bundle_path(macos_dmg_build_dir)
        dmg = macos_dmg_glob(macos_dmg_build_dir)
        assert dmg is not None, "DMG not found"

        failures: list[str] = []

        # DMG checks
        ok, output = codesign_verify(dmg)
        if not ok:
            failures.append(f"DMG codesign: {output}")

        ok, output = spctl_assess(dmg, "install")
        if not ok:
            failures.append(f"DMG spctl: {output}")

        ok, output = stapler_validate(dmg)
        if not ok:
            failures.append(f"DMG stapler: {output}")

        # App bundle checks
        ok, output = codesign_verify(app, deep=True, strict=True)
        if not ok:
            failures.append(f"App codesign: {output}")

        ok, output = spctl_assess(app, "execute")
        if not ok:
            failures.append(f"App spctl: {output}")

        ok, output = stapler_validate(app)
        if not ok:
            failures.append(f"App stapler: {output}")

        assert not failures, "Verification failures:\n" + "\n".join(failures)
