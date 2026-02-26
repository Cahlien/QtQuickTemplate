"""Session-scoped fixtures for Apple deploy pipeline integration tests."""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path

import pytest

# ---------------------------------------------------------------------------
# Platform guard — skip the entire suite on non-macOS
# ---------------------------------------------------------------------------

def pytest_collection_modifyitems(config: pytest.Config, items: list[pytest.Item]) -> None:
    """Skip all tests on non-macOS platforms."""
    if sys.platform != "darwin":
        skip = pytest.mark.skip(reason="Apple deploy tests require macOS")
        for item in items:
            item.add_marker(skip)


# ---------------------------------------------------------------------------
# Path fixtures
# ---------------------------------------------------------------------------

@pytest.fixture(scope="session")
def project_root() -> Path:
    """Repository root (parent of ``tests/``)."""
    return Path(__file__).resolve().parent.parent


@pytest.fixture(scope="session")
def ios_build_dir(project_root: Path) -> Path:
    """iOS build directory path (preset: ios-release)."""
    return project_root / "build" / "Qt_6_10_2_for_iOS"


@pytest.fixture(scope="session")
def macos_dmg_build_dir(project_root: Path) -> Path:
    """macOS DMG build directory path (preset: macos-release)."""
    return project_root / "build" / "Qt_6_10_2_for_macOS"


@pytest.fixture(scope="session")
def macos_appstore_build_dir(project_root: Path) -> Path:
    """macOS App Store build directory path (preset: macos-appstore)."""
    return project_root / "build" / "Qt_6_10_2_for_macOS_AppStore"


# ---------------------------------------------------------------------------
# CMake cache reader
# ---------------------------------------------------------------------------

def _read_cmake_cache(build_dir: Path) -> dict[str, str]:
    """Parse ``CMakeCache.txt`` into a ``{key: value}`` dict.

    Only simple ``KEY:TYPE=VALUE`` lines are parsed; comments and
    advanced entries are ignored.
    """
    cache_file = build_dir / "CMakeCache.txt"
    result: dict[str, str] = {}
    if not cache_file.is_file():
        return result
    for line in cache_file.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or line.startswith("//"):
            continue
        match = re.match(r"^([A-Za-z0-9_.-]+):[\w]+=(.*)$", line)
        if match:
            result[match.group(1)] = match.group(2)
    return result


# ---------------------------------------------------------------------------
# Credential fixtures
# ---------------------------------------------------------------------------

@pytest.fixture(scope="session")
def apple_team_id() -> str:
    """Apple Developer Team ID (``QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM``)."""
    return os.environ.get("QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM", "")


@pytest.fixture(scope="session")
def bundle_id() -> str:
    """App bundle identifier (``QTQUICKTEMPLATE_APPLE_BUNDLE_IDENTIFIER``)."""
    return os.environ.get("QTQUICKTEMPLATE_APPLE_BUNDLE_IDENTIFIER", "")


@pytest.fixture(scope="session")
def asc_api_key_id() -> str:
    """App Store Connect API key ID (``QTQUICKTEMPLATE_ASC_API_KEY_ID``)."""
    return os.environ.get("QTQUICKTEMPLATE_ASC_API_KEY_ID", "")


@pytest.fixture(scope="session")
def asc_api_issuer_id() -> str:
    """App Store Connect API issuer ID (``QTQUICKTEMPLATE_ASC_API_ISSUER_ID``)."""
    return os.environ.get("QTQUICKTEMPLATE_ASC_API_ISSUER_ID", "")


@pytest.fixture(scope="session")
def asc_api_key_path(asc_api_key_id: str) -> Path:
    """Path to the ASC API private key (.p8) file."""
    return Path.home() / ".appstoreconnect" / "private_keys" / f"AuthKey_{asc_api_key_id}.p8"


@pytest.fixture(scope="session")
def macos_notary_profile() -> str:
    """Keychain profile name for notarytool (``QTQUICKTEMPLATE_MACOS_NOTARY_KEYCHAIN_PROFILE``)."""
    return os.environ.get("QTQUICKTEMPLATE_MACOS_NOTARY_KEYCHAIN_PROFILE", "")


@pytest.fixture(scope="session")
def macos_sign_identity() -> str:
    """macOS Developer ID Application signing identity (``QTQUICKTEMPLATE_MACOS_APP_SIGN_IDENTITY``)."""
    return os.environ.get("QTQUICKTEMPLATE_MACOS_APP_SIGN_IDENTITY", "")


# ---------------------------------------------------------------------------
# Boolean credential gates
# ---------------------------------------------------------------------------

@pytest.fixture(scope="session")
def has_signing_credentials(apple_team_id: str) -> bool:
    """True if Apple signing credentials are configured."""
    return bool(apple_team_id)


@pytest.fixture(scope="session")
def has_asc_credentials(asc_api_key_path: Path, asc_api_key_id: str, asc_api_issuer_id: str) -> bool:
    """True if ASC API key file and credentials exist."""
    return asc_api_key_path.is_file() and bool(asc_api_key_id) and bool(asc_api_issuer_id)


@pytest.fixture(scope="session")
def has_notarization_credentials(macos_notary_profile: str) -> bool:
    """True if a notarization keychain profile is configured."""
    return bool(macos_notary_profile)


# ---------------------------------------------------------------------------
# Skip fixtures — call pytest.skip() when credentials are absent
# ---------------------------------------------------------------------------

@pytest.fixture()
def require_signing(has_signing_credentials: bool) -> None:
    """Skip the test if signing credentials are unavailable."""
    if not has_signing_credentials:
        pytest.skip("Signing credentials not available")


@pytest.fixture()
def require_asc(has_asc_credentials: bool) -> None:
    """Skip the test if ASC API credentials are unavailable."""
    if not has_asc_credentials:
        pytest.skip("ASC API credentials not available")


@pytest.fixture()
def require_notarization(has_notarization_credentials: bool) -> None:
    """Skip the test if notarization credentials are unavailable."""
    if not has_notarization_credentials:
        pytest.skip("Notarization credentials not available")


# ---------------------------------------------------------------------------
# Version fixture
# ---------------------------------------------------------------------------

@pytest.fixture(scope="session")
def project_version(macos_dmg_build_dir: Path) -> str | None:
    """Read ``QTQUICKTEMPLATE_APP_VERSION`` from the first available CMakeCache."""
    for build_dir in [macos_dmg_build_dir]:
        cache = _read_cmake_cache(build_dir)
        version = cache.get("QTQUICKTEMPLATE_APP_VERSION")
        if version:
            return version
    return None
