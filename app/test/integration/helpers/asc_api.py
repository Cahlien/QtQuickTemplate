"""App Store Connect API v2 helpers for build lookup and processing checks."""

from __future__ import annotations

import json
import subprocess
import time
import urllib.request
from pathlib import Path

import jwt  # PyJWT

ASC_API_BASE = "https://api.appstoreconnect.apple.com/v1"


def altool_upload(
    artifact_path: Path,
    api_key_id: str,
    api_issuer_id: str,
    *,
    timeout: int = 600,
) -> tuple[bool, str]:
    """Upload an artifact to App Store Connect via ``xcrun altool``.

    Returns *(success, combined_output)*.  Checks both the exit code
    and output for ``"UPLOAD FAILED"`` (altool can return 0 on failure).
    """
    result = subprocess.run(
        [
            "xcrun", "altool",
            "--upload-app",
            "-f", str(artifact_path),
            "--api-key", api_key_id,
            "--api-issuer", api_issuer_id,
        ],
        capture_output=True,
        text=True,
        timeout=timeout,
    )
    output = (result.stdout + "\n" + result.stderr).strip()
    # altool returns exit 0 even on validation failures, so check output
    # for all known error patterns
    has_error = (
        "UPLOAD FAILED" in output
        or "Failed to upload" in output
        or "ERROR:" in output
    )
    success = result.returncode == 0 and not has_error
    return success, output


def generate_asc_jwt(
    key_id: str,
    issuer_id: str,
    private_key_path: Path,
    *,
    duration_minutes: int = 20,
) -> str:
    """Create an ES256-signed JWT for the ASC API v2."""
    private_key = Path(private_key_path).read_text()
    now = int(time.time())
    payload = {
        "iss": issuer_id,
        "iat": now,
        "exp": now + duration_minutes * 60,
        "aud": "appstoreconnect-v1",
    }
    return jwt.encode(
        payload,
        private_key,
        algorithm="ES256",
        headers={"kid": key_id},
    )


def _asc_get(token: str, path: str) -> dict:
    """Perform an authenticated GET against the ASC API."""
    url = f"{ASC_API_BASE}{path}"
    req = urllib.request.Request(url, headers={
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    })
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read())


def _find_app_id(token: str, bundle_id: str) -> str | None:
    """Look up the ASC internal app ID for a bundle identifier."""
    data = _asc_get(token, f"/apps?filter[bundleId]={bundle_id}&limit=1")
    apps = data.get("data", [])
    return apps[0]["id"] if apps else None


def find_build(
    token: str,
    bundle_id: str,
    version_string: str,
    *,
    build_number: str | None = None,
) -> dict | None:
    """Find a build in ASC by bundle ID + version, optionally filtering by build number.

    Returns the build resource dict or ``None``.
    """
    app_id = _find_app_id(token, bundle_id)
    if app_id is None:
        return None

    path = (
        f"/builds?filter[app]={app_id}"
        f"&filter[preReleaseVersion.version]={version_string}"
        f"&sort=-uploadedDate"
        f"&limit=10"
    )
    data = _asc_get(token, path)
    builds = data.get("data", [])
    if not builds:
        return None

    if build_number is not None:
        for build in builds:
            if build["attributes"].get("version") == build_number:
                return build
        return None

    return builds[0]


def find_latest_build(
    token: str,
    bundle_id: str,
    *,
    platform: str | None = None,
) -> dict | None:
    """Find the most recently uploaded build for an app, regardless of version.

    Useful when the embedded artifact version may differ from local config
    (e.g., after a CMake reconfigure regenerated version files).

    *platform* can be ``"IOS"`` or ``"MAC_OS"`` to filter by platform.
    """
    app_id = _find_app_id(token, bundle_id)
    if app_id is None:
        return None

    path = f"/builds?filter[app]={app_id}&sort=-uploadedDate&limit=5"
    if platform:
        path += f"&filter[preReleaseVersion.platform]={platform}"
    data = _asc_get(token, path)
    builds = data.get("data", [])
    return builds[0] if builds else None


def wait_for_build(
    token: str,
    bundle_id: str,
    *,
    platform: str | None = None,
    uploaded_after: str | None = None,
    timeout_seconds: int = 600,
    poll_interval: int = 30,
) -> dict:
    """Poll ASC until a recently uploaded build appears.

    Looks for the most recent build for *bundle_id*, optionally filtered
    by *platform* (``"IOS"`` or ``"MAC_OS"``).  If *uploaded_after* is
    provided (ISO 8601 timestamp), only builds uploaded after that time
    are accepted.

    Returns the build resource dict.
    Raises ``TimeoutError`` if no matching build is found.
    """
    deadline = time.time() + timeout_seconds
    while True:
        build = find_latest_build(token, bundle_id, platform=platform)
        if build is not None:
            if uploaded_after is None:
                return build
            upload_date = build["attributes"].get("uploadedDate", "")
            if upload_date > uploaded_after:
                return build
        if time.time() >= deadline:
            raise TimeoutError(
                f"Build for {bundle_id} (platform={platform})"
                f" not found after {timeout_seconds}s"
            )
        time.sleep(poll_interval)


def get_build_processing_state(token: str, build_id: str) -> str:
    """Return the processing state for a build: PROCESSING, VALID, FAILED, or INVALID."""
    data = _asc_get(token, f"/builds/{build_id}")
    return data["data"]["attributes"]["processingState"]


def poll_build_processing(
    token: str,
    build_id: str,
    *,
    timeout_seconds: int = 1800,
    poll_interval: int = 60,
) -> str:
    """Poll a build's processing state until it leaves PROCESSING.

    Returns the final state (``VALID``, ``FAILED``, ``INVALID``).
    Raises ``TimeoutError`` if *timeout_seconds* elapses.
    """
    deadline = time.time() + timeout_seconds
    while True:
        state = get_build_processing_state(token, build_id)
        if state != "PROCESSING":
            return state
        if time.time() >= deadline:
            raise TimeoutError(
                f"Build {build_id} still PROCESSING after {timeout_seconds}s"
            )
        time.sleep(poll_interval)
