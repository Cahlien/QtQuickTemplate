"""macOS App Store PKG deploy pipeline integration tests.

Pipeline chain:
    GenerateMacOSVersion → MacAppStoreArchive → MacExportPkg → VerifyMacPkg → MacUploadASC
"""

from __future__ import annotations

import plistlib
from pathlib import Path

import pytest

from tests.helpers.artifacts import (
    macos_appstore_archive_app_path,
    macos_appstore_archive_path,
    macos_appstore_export_dir,
    macos_appstore_version_xcconfig,
    macos_pkg_path,
    parse_version_xcconfig,
)
from tests.helpers.asc_api import altool_upload
from tests.helpers.codesign import (
    codesign_display,
    codesign_verify,
    parse_codesign_authority,
    parse_codesign_team_id,
)

pytestmark = [pytest.mark.macos_appstore]


# ---------------------------------------------------------------------------
# GenerateMacOSVersion
# ---------------------------------------------------------------------------

class TestMacOSAppStoreVersionGeneration:
    """Verify ``GenerateMacOSVersion`` target output."""

    def test_xcconfig_exists(self, macos_appstore_build_dir: Path) -> None:
        """version.xcconfig must exist after GenerateMacOSVersion."""
        path = macos_appstore_version_xcconfig(macos_appstore_build_dir)
        assert path.is_file(), f"version.xcconfig not found at {path}"

    def test_marketing_version_format(self, macos_appstore_build_dir: Path) -> None:
        """MARKETING_VERSION must have at least major.minor components."""
        cfg = parse_version_xcconfig(
            macos_appstore_version_xcconfig(macos_appstore_build_dir)
        )
        mv = cfg.get("MARKETING_VERSION", "")
        parts = mv.split(".")
        assert len(parts) >= 2, f"MARKETING_VERSION '{mv}' should have at least major.minor"

    def test_current_project_version_format(self, macos_appstore_build_dir: Path) -> None:
        """macOS uses 3-part version (major.minor.patch), unlike iOS 4-part."""
        cfg = parse_version_xcconfig(
            macos_appstore_version_xcconfig(macos_appstore_build_dir)
        )
        cpv = cfg.get("CURRENT_PROJECT_VERSION", "")
        parts = cpv.split(".")
        assert len(parts) == 3, (
            f"macOS CURRENT_PROJECT_VERSION '{cpv}' should be 3-part (major.minor.patch)"
        )


# ---------------------------------------------------------------------------
# MacAppStoreArchive
# ---------------------------------------------------------------------------

class TestMacOSAppStoreArchive:
    """Verify ``MacAppStoreArchive`` target output."""

    def test_xcarchive_exists(self, macos_appstore_build_dir: Path) -> None:
        """xcarchive directory must exist after MacAppStoreArchive."""
        archive = macos_appstore_archive_path(macos_appstore_build_dir)
        assert archive.is_dir(), f"xcarchive not found at {archive}"

    def test_info_plist_exists(self, macos_appstore_build_dir: Path) -> None:
        """xcarchive must contain an Info.plist."""
        plist = macos_appstore_archive_path(macos_appstore_build_dir) / "Info.plist"
        assert plist.is_file(), "xcarchive Info.plist missing"

    def test_app_bundle_exists(self, macos_appstore_build_dir: Path) -> None:
        """App bundle must exist inside the xcarchive."""
        app = macos_appstore_archive_app_path(macos_appstore_build_dir)
        assert app.is_dir(), f"App bundle not found inside archive at {app}"

    def test_application_properties_present(self, macos_appstore_build_dir: Path) -> None:
        """Xcode 26 workaround: verify ApplicationProperties was patched in."""
        plist_path = macos_appstore_archive_path(macos_appstore_build_dir) / "Info.plist"
        with open(plist_path, "rb") as f:
            plist = plistlib.load(f)
        assert "ApplicationProperties" in plist, (
            "Info.plist missing ApplicationProperties — "
            "PatchArchiveInfo.cmake may not have run"
        )

    def test_application_properties_keys(self, macos_appstore_build_dir: Path) -> None:
        """Verify required keys in ApplicationProperties."""
        plist_path = macos_appstore_archive_path(macos_appstore_build_dir) / "Info.plist"
        with open(plist_path, "rb") as f:
            plist = plistlib.load(f)
        app_props = plist.get("ApplicationProperties", {})
        required_keys = [
            "ApplicationPath",
            "CFBundleIdentifier",
            "CFBundleShortVersionString",
            "CFBundleVersion",
            "SigningIdentity",
            "Team",
        ]
        missing = [k for k in required_keys if k not in app_props]
        assert not missing, f"ApplicationProperties missing keys: {missing}"

    def test_correct_bundle_id(
        self,
        macos_appstore_build_dir: Path,
        bundle_id: str,
    ) -> None:
        """Archived app must use the expected bundle identifier."""
        app = macos_appstore_archive_app_path(macos_appstore_build_dir)
        info_plist = app / "Contents" / "Info.plist"
        with open(info_plist, "rb") as f:
            plist = plistlib.load(f)
        assert plist.get("CFBundleIdentifier") == bundle_id

    def test_qt_frameworks_deployed(self, macos_appstore_build_dir: Path) -> None:
        """macdeployqt -appstore-compliant should have deployed Qt frameworks."""
        app = macos_appstore_archive_app_path(macos_appstore_build_dir)
        frameworks = app / "Contents" / "Frameworks"
        assert frameworks.is_dir(), "Frameworks directory missing from archived app"
        qt_frameworks = list(frameworks.glob("Qt*.framework"))
        assert len(qt_frameworks) > 0, "No Qt frameworks found in archived app"

    def test_app_signed_with_apple_distribution(
        self,
        macos_appstore_build_dir: Path,
    ) -> None:
        """Archived app must be signed with an Apple Distribution identity."""
        app = macos_appstore_archive_app_path(macos_appstore_build_dir)
        ok, output = codesign_display(app)
        assert ok, f"codesign display failed:\n{output}"
        authority = parse_codesign_authority(output)
        assert authority and authority.startswith("Apple Distribution"), (
            f"Expected 'Apple Distribution' signing, got: {authority}"
        )

    def test_correct_team_id(
        self,
        macos_appstore_build_dir: Path,
        apple_team_id: str,
    ) -> None:
        """Archived app must be signed with the expected team identifier."""
        app = macos_appstore_archive_app_path(macos_appstore_build_dir)
        ok, output = codesign_display(app)
        assert ok
        team = parse_codesign_team_id(output)
        assert team == apple_team_id, f"Expected team {apple_team_id}, got {team}"


# ---------------------------------------------------------------------------
# MacExportPkg
# ---------------------------------------------------------------------------

class TestMacOSExportPkg:
    """Verify ``MacExportPkg`` target output."""

    def test_export_dir_exists(self, macos_appstore_build_dir: Path) -> None:
        """macOS export directory must exist after MacExportPkg."""
        assert macos_appstore_export_dir(macos_appstore_build_dir).is_dir()

    def test_pkg_exists(self, macos_appstore_build_dir: Path) -> None:
        """At least one .pkg must exist in the export directory."""
        pkg = macos_pkg_path(macos_appstore_build_dir)
        assert pkg is not None, "No .pkg found in export directory"

    def test_pkg_size(self, macos_appstore_build_dir: Path) -> None:
        """Exported PKG must be larger than 1 MB."""
        pkg = macos_pkg_path(macos_appstore_build_dir)
        assert pkg is not None
        size_mb = pkg.stat().st_size / (1024 * 1024)
        assert size_mb > 1, f"PKG suspiciously small: {size_mb:.1f} MB"

    def test_export_options_method(self, macos_appstore_build_dir: Path) -> None:
        """ExportOptions.plist should use 'app-store' or 'app-store-connect'."""
        export_dir = macos_appstore_export_dir(macos_appstore_build_dir)
        plist_candidates = list(export_dir.glob("*ExportOptions*.plist"))
        # Also check the cmake binary dir for the generated ExportOptions
        cmake_candidates = list(
            macos_appstore_build_dir.glob("**/QtQuickTemplate_MacAppStoreExportOptions.plist")
        )
        candidates = plist_candidates + cmake_candidates
        assert candidates, "No ExportOptions plist found"
        plist_path = candidates[0]
        with open(plist_path, "rb") as f:
            plist = plistlib.load(f)
        method = plist.get("method", "")
        assert method in ("app-store", "app-store-connect"), (
            f"Export method should be 'app-store' or 'app-store-connect', got: {method}"
        )

    def test_distribution_summary_exists(self, macos_appstore_build_dir: Path) -> None:
        """Export directory must contain a DistributionSummary file."""
        export_dir = macos_appstore_export_dir(macos_appstore_build_dir)
        summaries = list(export_dir.glob("DistributionSummary*"))
        assert summaries, "DistributionSummary not found in export directory"


# ---------------------------------------------------------------------------
# MacUploadASC — real upload
# ---------------------------------------------------------------------------

@pytest.mark.asc_upload
@pytest.mark.slow
class TestMacOSAppStoreUpload:
    """Upload the pre-built PKG to App Store Connect via ``xcrun altool``."""

    @pytest.mark.timeout(600)
    def test_upload_succeeds(
        self,
        macos_appstore_build_dir: Path,
        asc_api_key_id: str,
        asc_api_issuer_id: str,
        require_asc: None,
    ) -> None:
        """PKG must upload to App Store Connect without errors."""
        pkg = macos_pkg_path(macos_appstore_build_dir)
        assert pkg is not None, "No .pkg found — cannot upload"
        ok, output = altool_upload(pkg, asc_api_key_id, asc_api_issuer_id)
        assert ok, f"macOS PKG upload failed:\n{output}"


# ---------------------------------------------------------------------------
# ASC processing — real API check
# ---------------------------------------------------------------------------

@pytest.mark.asc_processing
@pytest.mark.slow
class TestMacOSAppStoreAscProcessing:
    """Poll ASC until the macOS App Store build finishes processing."""

    @pytest.mark.timeout(2400)
    def test_build_processes_to_valid(
        self,
        bundle_id: str,
        asc_api_key_id: str,
        asc_api_issuer_id: str,
        asc_api_key_path: Path,
        require_asc: None,
    ) -> None:
        """Uploaded macOS build must reach VALID processing state in ASC."""
        from tests.helpers.asc_api import (
            find_latest_build,
            generate_asc_jwt,
            poll_build_processing,
        )

        token = generate_asc_jwt(asc_api_key_id, asc_api_issuer_id, asc_api_key_path)

        build = find_latest_build(token, bundle_id, platform="MAC_OS")
        assert build is not None, f"No macOS build found in ASC for {bundle_id}"

        attrs = build["attributes"]
        state = attrs.get("processingState")
        if state == "VALID":
            return  # already processed
        assert state == "PROCESSING", f"Unexpected initial state: {state}"

        state = poll_build_processing(
            token,
            build["id"],
            timeout_seconds=2100,
            poll_interval=60,
        )
        assert state == "VALID", f"Build processing ended with state: {state}"
