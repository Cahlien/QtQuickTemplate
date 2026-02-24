"""iOS App Store deploy pipeline integration tests.

Pipeline chain:
    GenerateIOSVersion → IOSArchive → IOSExportIPA → VerifyIOSIPA → IOSUploadASC
"""

from __future__ import annotations

import plistlib
from pathlib import Path

import pytest

from tests.helpers.artifacts import (
    ios_archive_app_path,
    ios_archive_path,
    ios_export_dir,
    ios_ipa_path,
    ios_version_xcconfig,
    parse_version_xcconfig,
)
from tests.helpers.asc_api import altool_upload
from tests.helpers.codesign import (
    codesign_display,
    codesign_verify,
    parse_codesign_authority,
    parse_codesign_team_id,
)

pytestmark = [pytest.mark.ios]


# ---------------------------------------------------------------------------
# GenerateIOSVersion
# ---------------------------------------------------------------------------

class TestIOSVersionGeneration:
    """Verify ``GenerateIOSVersion`` target output."""

    def test_xcconfig_exists(self, ios_build_dir: Path) -> None:
        """version.xcconfig must exist after GenerateIOSVersion."""
        path = ios_version_xcconfig(ios_build_dir)
        assert path.is_file(), f"version.xcconfig not found at {path}"

    def test_marketing_version_format(self, ios_build_dir: Path) -> None:
        """MARKETING_VERSION must have at least major.minor components."""
        cfg = parse_version_xcconfig(ios_version_xcconfig(ios_build_dir))
        mv = cfg.get("MARKETING_VERSION", "")
        parts = mv.split(".")
        assert len(parts) >= 2, f"MARKETING_VERSION '{mv}' should have at least major.minor"

    def test_current_project_version_format(self, ios_build_dir: Path) -> None:
        """iOS CURRENT_PROJECT_VERSION must be 4-part (major.minor.patch.build)."""
        cfg = parse_version_xcconfig(ios_version_xcconfig(ios_build_dir))
        cpv = cfg.get("CURRENT_PROJECT_VERSION", "")
        parts = cpv.split(".")
        assert len(parts) == 4, (
            f"iOS CURRENT_PROJECT_VERSION '{cpv}' should be 4-part (major.minor.patch.build)"
        )


# ---------------------------------------------------------------------------
# IOSArchive
# ---------------------------------------------------------------------------

class TestIOSArchive:
    """Verify ``IOSArchive`` target output."""

    def test_xcarchive_exists(self, ios_build_dir: Path) -> None:
        """xcarchive directory must exist after IOSArchive."""
        archive = ios_archive_path(ios_build_dir)
        assert archive.is_dir(), f"xcarchive not found at {archive}"

    def test_info_plist_exists(self, ios_build_dir: Path) -> None:
        """xcarchive must contain an Info.plist."""
        plist = ios_archive_path(ios_build_dir) / "Info.plist"
        assert plist.is_file(), "xcarchive Info.plist missing"

    def test_application_properties_present(self, ios_build_dir: Path) -> None:
        """xcarchive Info.plist must contain ApplicationProperties."""
        plist_path = ios_archive_path(ios_build_dir) / "Info.plist"
        with open(plist_path, "rb") as f:
            plist = plistlib.load(f)
        assert "ApplicationProperties" in plist, (
            "Info.plist missing ApplicationProperties — archive may be malformed"
        )

    def test_app_bundle_exists(self, ios_build_dir: Path) -> None:
        """App bundle must exist inside the xcarchive."""
        app = ios_archive_app_path(ios_build_dir)
        assert app.is_dir(), f"App bundle not found inside archive at {app}"

    def test_correct_bundle_id(self, ios_build_dir: Path, bundle_id: str) -> None:
        """Archived app must use the expected bundle identifier."""
        app = ios_archive_app_path(ios_build_dir)
        info_plist = app / "Info.plist"
        with open(info_plist, "rb") as f:
            plist = plistlib.load(f)
        assert plist.get("CFBundleIdentifier") == bundle_id

    def test_app_is_signed(self, ios_build_dir: Path) -> None:
        """Archived app bundle must pass codesign verification."""
        app = ios_archive_app_path(ios_build_dir)
        ok, output = codesign_verify(app)
        assert ok, f"App bundle not signed:\n{output}"

    def test_signed_by_apple_distribution(self, ios_build_dir: Path) -> None:
        """Archived app must be signed with an Apple Distribution identity."""
        app = ios_archive_app_path(ios_build_dir)
        ok, output = codesign_display(app)
        assert ok, f"codesign display failed:\n{output}"
        authority = parse_codesign_authority(output)
        assert authority and authority.startswith("Apple Distribution"), (
            f"Expected 'Apple Distribution' signing, got: {authority}"
        )

    def test_correct_team_id(self, ios_build_dir: Path, apple_team_id: str) -> None:
        """Archived app must be signed with the expected team identifier."""
        app = ios_archive_app_path(ios_build_dir)
        ok, output = codesign_display(app)
        assert ok
        team = parse_codesign_team_id(output)
        assert team == apple_team_id, f"Expected team {apple_team_id}, got {team}"


# ---------------------------------------------------------------------------
# IOSExportIPA
# ---------------------------------------------------------------------------

class TestIOSExportIPA:
    """Verify ``IOSExportIPA`` target output."""

    def test_export_dir_exists(self, ios_build_dir: Path) -> None:
        """iOS export directory must exist after IOSExportIPA."""
        assert ios_export_dir(ios_build_dir).is_dir()

    def test_ipa_exists(self, ios_build_dir: Path) -> None:
        """At least one .ipa must exist in the export directory."""
        ipa = ios_ipa_path(ios_build_dir)
        assert ipa is not None, "No .ipa found in export directory"

    def test_ipa_size(self, ios_build_dir: Path) -> None:
        """Exported IPA must be larger than 1 MB."""
        ipa = ios_ipa_path(ios_build_dir)
        assert ipa is not None
        size_mb = ipa.stat().st_size / (1024 * 1024)
        assert size_mb > 1, f"IPA suspiciously small: {size_mb:.1f} MB"


# ---------------------------------------------------------------------------
# IOSUploadASC — real upload
# ---------------------------------------------------------------------------

@pytest.mark.asc_upload
@pytest.mark.slow
class TestIOSUpload:
    """Upload the pre-built IPA to App Store Connect via ``xcrun altool``."""

    @pytest.mark.timeout(600)
    def test_upload_succeeds(
        self,
        ios_build_dir: Path,
        asc_api_key_id: str,
        asc_api_issuer_id: str,
        require_asc: None,
    ) -> None:
        """IPA must upload to App Store Connect without errors."""
        ipa = ios_ipa_path(ios_build_dir)
        assert ipa is not None, "No .ipa found — cannot upload"
        ok, output = altool_upload(ipa, asc_api_key_id, asc_api_issuer_id)
        assert ok, f"iOS IPA upload failed:\n{output}"


# ---------------------------------------------------------------------------
# ASC processing — real API check
# ---------------------------------------------------------------------------

@pytest.mark.asc_processing
@pytest.mark.slow
class TestIOSAscProcessing:
    """Poll ASC until the iOS build finishes processing."""

    @pytest.mark.timeout(2400)
    def test_build_processes_to_valid(
        self,
        bundle_id: str,
        asc_api_key_id: str,
        asc_api_issuer_id: str,
        asc_api_key_path: Path,
        require_asc: None,
    ) -> None:
        """Uploaded iOS build must reach VALID processing state in ASC."""
        from tests.helpers.asc_api import (
            find_latest_build,
            generate_asc_jwt,
            poll_build_processing,
        )

        token = generate_asc_jwt(asc_api_key_id, asc_api_issuer_id, asc_api_key_path)

        build = find_latest_build(token, bundle_id, platform="IOS")
        assert build is not None, f"No iOS build found in ASC for {bundle_id}"

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
