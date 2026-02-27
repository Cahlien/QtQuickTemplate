"""Android SDK, NDK, and Java home autodetection for all platforms."""

from __future__ import annotations

import os
import re
import shutil
import subprocess
from pathlib import Path

from configure_env._types import Platform

_VERSION_RE = re.compile(r"^\d+")
_NDK_RELEASE_RE = re.compile(r"android-ndk-(r\w+)$")


def detect_android_sdk(home: Path, plat: Platform) -> str:
    """Return the Android SDK root directory or ``""``."""
    candidates: list[Path] = []
    if plat == Platform.DARWIN:
        candidates = [home / "Library" / "Android" / "sdk", home / "Android" / "Sdk"]
    elif plat == Platform.LINUX:
        candidates = [
            home / "Android" / "Sdk",
            Path("/opt/android-sdk"),
            home / "android-sdk",
        ]
    elif plat == Platform.WINDOWS:
        localappdata = os.environ.get("LOCALAPPDATA", "")
        if localappdata:
            candidates.append(Path(localappdata) / "Android" / "Sdk")
        candidates.append(home / "AppData" / "Local" / "Android" / "Sdk")
        candidates.append(Path("C:/Android/Sdk"))

    for d in candidates:
        if d.is_dir():
            return str(d)

    for var in ("ANDROID_SDK_ROOT", "ANDROID_HOME"):
        val = os.environ.get(var, "")
        if val and Path(val).is_dir():
            return val

    return ""


def _read_qt_ndk_release_tag(qt_abi_root: str) -> str:
    """Extract the NDK release tag (e.g. ``r27c``) from Qt's ``qdevice.pri``.

    Qt ships ``mkspecs/qdevice.pri`` in every Android ABI root with a line
    like ``DEFAULT_ANDROID_NDK_ROOT = /opt/android/android-ndk-r27c``.
    """
    if not qt_abi_root:
        return ""
    qdevice = Path(qt_abi_root) / "mkspecs" / "qdevice.pri"
    if not qdevice.is_file():
        return ""
    try:
        for line in qdevice.read_text(encoding="utf-8").splitlines():
            if line.startswith("DEFAULT_ANDROID_NDK_ROOT"):
                _, _, value = line.partition("=")
                m = _NDK_RELEASE_RE.search(value.strip())
                if m:
                    return m.group(1)
    except OSError:
        pass
    return ""


def _ndk_release_name(ndk_path: Path) -> str:
    """Read ``Pkg.ReleaseName`` from an NDK's ``source.properties``."""
    props = ndk_path / "source.properties"
    if not props.is_file():
        return ""
    try:
        for line in props.read_text(encoding="utf-8").splitlines():
            if line.startswith("Pkg.ReleaseName"):
                _, _, value = line.partition("=")
                return value.strip()
    except OSError:
        pass
    return ""


def detect_android_ndk(sdk_root: str, qt_abi_root: str = "") -> str:
    """Return the NDK directory that matches the Qt-required release, or latest.

    If *qt_abi_root* is provided, reads the NDK release tag from Qt's
    ``mkspecs/qdevice.pri`` and finds the installed NDK whose
    ``source.properties`` ``Pkg.ReleaseName`` matches.  Falls back to the
    latest installed NDK if no match is found.
    """
    if not sdk_root:
        return ""
    ndk_dir = Path(sdk_root) / "ndk"
    if not ndk_dir.is_dir():
        return ""
    def _ndk_version_key(p: Path) -> tuple[int, ...]:
        try:
            return tuple(int(x) for x in p.name.split("."))
        except ValueError:
            return (0,)

    try:
        installed = sorted(
            (d for d in ndk_dir.iterdir() if d.is_dir() and _VERSION_RE.match(d.name)),
            key=_ndk_version_key,
        )
    except OSError:
        return ""
    if not installed:
        return ""

    tag = _read_qt_ndk_release_tag(qt_abi_root)
    if tag:
        for ndk_path in installed:
            if _ndk_release_name(ndk_path) == tag:
                return str(ndk_path)

    return str(installed[-1])


def detect_java_home(plat: Platform) -> str:
    """Return the detected JAVA_HOME or ``""``."""
    if plat == Platform.DARWIN:
        try:
            result = subprocess.run(
                ["/usr/libexec/java_home"],
                capture_output=True,
                text=True,
                check=True,
            )
            val = result.stdout.strip()
            if val and Path(val).is_dir():
                return val
        except (subprocess.CalledProcessError, FileNotFoundError, OSError):
            pass

    if plat == Platform.LINUX:
        candidates = [
            "/usr/lib/jvm/java-21-openjdk",
            "/usr/lib/jvm/java-21-openjdk-amd64",
            "/usr/lib/jvm/java-21-openjdk-aarch64",
            "/usr/lib/jvm/java-17-openjdk",
            "/usr/lib/jvm/java-17-openjdk-amd64",
            "/usr/lib/jvm/java-17-openjdk-aarch64",
        ]
        for d in candidates:
            if Path(d).is_dir():
                return d
        java_bin = shutil.which("java")
        if java_bin:
            resolved = Path(java_bin).resolve()
            jdk_root = resolved.parent.parent
            if (jdk_root / "bin" / "java").exists():
                return str(jdk_root)

    if plat == Platform.WINDOWS:
        search_roots = [
            Path("C:/Program Files/Eclipse Adoptium"),
            Path("C:/Program Files/Java"),
        ]
        for root in search_roots:
            if root.is_dir():
                jdks = sorted(
                    (d for d in root.iterdir() if d.is_dir() and "jdk" in d.name.lower()),
                    key=lambda p: p.name,
                    reverse=True,
                )
                if jdks:
                    return str(jdks[0])
        ms_root = Path("C:/Program Files/Microsoft")
        if ms_root.is_dir():
            ms_jdks = sorted(
                (d for d in ms_root.iterdir() if d.is_dir() and d.name.startswith("jdk-")),
                key=lambda p: p.name,
                reverse=True,
            )
            if ms_jdks:
                return str(ms_jdks[0])

    val = os.environ.get("JAVA_HOME", "")
    if val and Path(val).is_dir():
        return val

    return ""
