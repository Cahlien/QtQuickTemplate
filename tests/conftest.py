"""Session-scoped fixtures for Apple deploy pipeline integration tests."""

from __future__ import annotations

import re
import sys
from pathlib import Path

import pytest

# ---------------------------------------------------------------------------
# Platform guard — skip the entire suite on non-macOS
# ---------------------------------------------------------------------------

def pytest_collection_modifyitems(config: pytest.Config, items: list[pytest.Item]) -> None:
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
    return project_root / "build" / "Qt_6_10_2_for_iOS"


@pytest.fixture(scope="session")
def macos_dmg_build_dir(project_root: Path) -> Path:
    return project_root / "build" / "Qt_6_10_2_for_macOS"


@pytest.fixture(scope="session")
def macos_appstore_build_dir(project_root: Path) -> Path:
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
    return "WC33S27B73"


@pytest.fixture(scope="session")
def bundle_id() -> str:
    return "dev.crowell.qtquicktemplate"


@pytest.fixture(scope="session")
def asc_api_key_id() -> str:
    return "NV3YP3T2C5"


@pytest.fixture(scope="session")
def asc_api_issuer_id() -> str:
    return "f143497c-fb10-4e07-bfc0-162ed7dffdf3"


@pytest.fixture(scope="session")
def asc_api_key_path(asc_api_key_id: str) -> Path:
    return Path.home() / ".appstoreconnect" / "private_keys" / f"AuthKey_{asc_api_key_id}.p8"


@pytest.fixture(scope="session")
def macos_notary_profile() -> str:
    return "cti-notary"


@pytest.fixture(scope="session")
def macos_sign_identity() -> str:
    return "Developer ID Application: Confederated Technologies, Inc. (WC33S27B73)"


# ---------------------------------------------------------------------------
# Boolean credential gates
# ---------------------------------------------------------------------------

@pytest.fixture(scope="session")
def has_signing_credentials(apple_team_id: str) -> bool:
    return bool(apple_team_id)


@pytest.fixture(scope="session")
def has_asc_credentials(asc_api_key_path: Path, asc_api_key_id: str, asc_api_issuer_id: str) -> bool:
    return asc_api_key_path.is_file() and bool(asc_api_key_id) and bool(asc_api_issuer_id)


@pytest.fixture(scope="session")
def has_notarization_credentials(macos_notary_profile: str) -> bool:
    return bool(macos_notary_profile)


# ---------------------------------------------------------------------------
# Skip fixtures — call pytest.skip() when credentials are absent
# ---------------------------------------------------------------------------

@pytest.fixture()
def require_signing(has_signing_credentials: bool) -> None:
    if not has_signing_credentials:
        pytest.skip("Signing credentials not available")


@pytest.fixture()
def require_asc(has_asc_credentials: bool) -> None:
    if not has_asc_credentials:
        pytest.skip("ASC API credentials not available")


@pytest.fixture()
def require_notarization(has_notarization_credentials: bool) -> None:
    if not has_notarization_credentials:
        pytest.skip("Notarization credentials not available")


# ---------------------------------------------------------------------------
# Version fixture
# ---------------------------------------------------------------------------

@pytest.fixture(scope="session")
def project_version(macos_dmg_build_dir: Path) -> str | None:
    """Read ``CMAKE_PROJECT_VERSION`` from the first available CMakeCache."""
    for build_dir in [macos_dmg_build_dir]:
        cache = _read_cmake_cache(build_dir)
        version = cache.get("CMAKE_PROJECT_VERSION")
        if version:
            return version
    return None
