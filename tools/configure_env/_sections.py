"""Section builders that produce the list of variables to prompt."""

from __future__ import annotations

from pathlib import Path

from configure_env._types import EnvVar, Platform, Section
from configure_env._detect_android import (
    detect_android_ndk,
    detect_android_sdk,
    detect_java_home,
)
from configure_env._detect_qt import detect_qt_platform_root


def build_qt_sdk_section(
    plat: Platform,
    home: Path,
    defaults: dict[str, str],
) -> Section:
    variables: list[EnvVar] = []

    if plat == Platform.DARWIN:
        detected_macos = detect_qt_platform_root("macos", home, plat)
        detected_ios = detect_qt_platform_root("ios", home, plat)
        variables.append(EnvVar(
            "QT_MACOS_ROOT", "macOS Qt SDK root",
            defaults.get("QT_MACOS_ROOT", detected_macos), True,
        ))
        variables.append(EnvVar(
            "QT_IOS_ROOT", "iOS Qt SDK root",
            defaults.get("QT_IOS_ROOT", detected_ios), True,
        ))
    elif plat == Platform.LINUX:
        detected_linux = detect_qt_platform_root("gcc_64", home, plat)
        variables.append(EnvVar(
            "QT_LINUX_ROOT", "Linux Qt SDK root",
            defaults.get("QT_LINUX_ROOT", detected_linux), True,
        ))
    elif plat == Platform.WINDOWS:
        detected_win = detect_qt_platform_root("msvc2022_64", home, plat)
        variables.append(EnvVar(
            "QT_WINDOWS_ROOT", "Windows Qt SDK root",
            defaults.get("QT_WINDOWS_ROOT", detected_win), True,
        ))

    return Section("Qt SDK Paths", variables)


def build_host_root_var(
    plat: Platform,
    result: dict[str, str],
    defaults: dict[str, str],
) -> EnvVar:
    """Return the QT_HOST_ROOT variable with a default derived from the platform root."""
    if plat == Platform.DARWIN:
        host_default = result.get("QT_MACOS_ROOT", defaults.get("QT_MACOS_ROOT", ""))
    elif plat == Platform.LINUX:
        host_default = result.get("QT_LINUX_ROOT", defaults.get("QT_LINUX_ROOT", ""))
    elif plat == Platform.WINDOWS:
        host_default = result.get("QT_WINDOWS_ROOT", defaults.get("QT_WINDOWS_ROOT", ""))
    else:
        host_default = ""

    return EnvVar(
        "QT_HOST_ROOT",
        "Host Qt root for cross-compilation",
        defaults.get("QT_HOST_ROOT", host_default),
        True,
    )


def build_android_qt_section(
    plat: Platform,
    home: Path,
    defaults: dict[str, str],
) -> Section:
    abis = [
        ("QT_ANDROID_ARM64_ROOT", "Qt for Android arm64-v8a", "android_arm64_v8a"),
        ("QT_ANDROID_ARMV7_ROOT", "Qt for Android armeabi-v7a", "android_armv7"),
        ("QT_ANDROID_X86_64_ROOT", "Qt for Android x86_64", "android_x86_64"),
        ("QT_ANDROID_X86_ROOT", "Qt for Android x86", "android_x86"),
    ]
    variables: list[EnvVar] = []
    for name, desc, subdir in abis:
        detected = detect_qt_platform_root(subdir, home, plat)
        variables.append(EnvVar(name, desc, defaults.get(name, detected), True))
    return Section("Android Qt SDK Roots", variables)


def build_apple_sections(
    defaults: dict[str, str],
) -> list[Section]:
    signing = Section("Apple Code Signing", [
        EnvVar("APPLE_DEVELOPMENT_TEAM", "Apple Development Team ID (10-char)",
               defaults.get("APPLE_DEVELOPMENT_TEAM", "")),
        EnvVar("MACOS_APP_SIGN_IDENTITY",
               "macOS app signing identity (e.g. Developer ID Application: ...)",
               defaults.get("MACOS_APP_SIGN_IDENTITY", "")),
        EnvVar("MACOS_DMG_SIGN_IDENTITY",
               "macOS DMG signing identity (e.g. Developer ID Application: ...)",
               defaults.get("MACOS_DMG_SIGN_IDENTITY", "")),
        EnvVar("MACOS_NOTARY_KEYCHAIN_PROFILE",
               "macOS notarization keychain profile name",
               defaults.get("MACOS_NOTARY_KEYCHAIN_PROFILE", "")),
        EnvVar("MACOS_APP_STORE_PROVISIONING_PROFILE",
               "macOS App Store provisioning profile name (leave empty to skip)",
               defaults.get("MACOS_APP_STORE_PROVISIONING_PROFILE", "")),
    ])

    asc = Section("App Store Connect", [
        EnvVar("ASC_API_KEY_ID", "App Store Connect API Key ID",
               defaults.get("ASC_API_KEY_ID", "")),
        EnvVar("ASC_API_ISSUER_ID", "App Store Connect Issuer ID",
               defaults.get("ASC_API_ISSUER_ID", "")),
    ])

    ios = Section("iOS Signing", [
        EnvVar("IOS_PROVISIONING_PROFILE",
               "iOS provisioning profile name (leave empty to skip)",
               defaults.get("IOS_PROVISIONING_PROFILE", "")),
    ])

    return [signing, asc, ios]


def build_android_sdk_sections(
    plat: Platform,
    home: Path,
    defaults: dict[str, str],
    result: dict[str, str],
) -> list[Section]:
    detected_sdk = detect_android_sdk(home, plat)
    sdk_var = EnvVar("ANDROID_SDK_ROOT", "Android SDK root",
                     defaults.get("ANDROID_SDK_ROOT", detected_sdk), True)

    sdk_root = result.get("ANDROID_SDK_ROOT", defaults.get("ANDROID_SDK_ROOT", detected_sdk))
    qt_abi_root = (
        result.get("QT_ANDROID_ARM64_ROOT")
        or defaults.get("QT_ANDROID_ARM64_ROOT")
        or result.get("QT_ANDROID_ARMV7_ROOT")
        or defaults.get("QT_ANDROID_ARMV7_ROOT")
        or result.get("QT_ANDROID_X86_64_ROOT")
        or defaults.get("QT_ANDROID_X86_64_ROOT")
        or result.get("QT_ANDROID_X86_ROOT")
        or defaults.get("QT_ANDROID_X86_ROOT")
        or ""
    )
    detected_ndk = detect_android_ndk(sdk_root, qt_abi_root)
    ndk_default = detected_ndk or defaults.get("ANDROID_NDK_ROOT", "")
    ndk_var = EnvVar("ANDROID_NDK_ROOT", "Android NDK root", ndk_default, True)

    detected_java = detect_java_home(plat)
    java_var = EnvVar("JAVA_HOME", "Java JDK home (JDK 17+ recommended)",
                      defaults.get("JAVA_HOME", detected_java), True)

    sdk_section = Section("Android SDK", [sdk_var, ndk_var, java_var])

    signing_section = Section("Android Signing", [
        EnvVar("ANDROID_KEYSTORE_PATH", "Keystore file path",
               defaults.get("ANDROID_KEYSTORE_PATH", ""), True),
        EnvVar("ANDROID_KEYSTORE_PASSWORD", "Keystore password",
               defaults.get("ANDROID_KEYSTORE_PASSWORD", "")),
        EnvVar("ANDROID_KEY_ALIAS", "Key alias",
               defaults.get("ANDROID_KEY_ALIAS", "")),
        EnvVar("ANDROID_KEY_PASSWORD", "Key password",
               defaults.get("ANDROID_KEY_PASSWORD", "")),
    ])

    play_section = Section("Google Play Upload", [
        EnvVar("ANDROID_PLAY_SERVICE_ACCOUNT_FILE",
               "Play Console service account JSON path (leave empty to skip)",
               defaults.get("ANDROID_PLAY_SERVICE_ACCOUNT_FILE", ""), True),
        EnvVar("ANDROID_PLAY_TRACK", "Play Console release track",
               defaults.get("ANDROID_PLAY_TRACK", "internal")),
        EnvVar("ANDROID_PLAY_RELEASE_STATUS", "Play Console release status",
               defaults.get("ANDROID_PLAY_RELEASE_STATUS", "completed")),
    ])

    return [sdk_section, signing_section, play_section]


def build_linux_signing_section(
    defaults: dict[str, str],
) -> Section:
    return Section("Linux AppImage Signing", [
        EnvVar("GPG_KEY_ID", "GPG key ID for AppImage signing (leave empty to skip)",
               defaults.get("GPG_KEY_ID", "")),
    ])


def derive_defaults(
    plat: Platform,
    result: dict[str, str],
    defaults: dict[str, str],
) -> None:
    """Set Qt6_DIR and CMAKE_PREFIX_PATH from the platform root."""
    if plat == Platform.DARWIN:
        root = result.get("QT_MACOS_ROOT", defaults.get("QT_MACOS_ROOT", ""))
    elif plat == Platform.LINUX:
        root = result.get("QT_LINUX_ROOT", defaults.get("QT_LINUX_ROOT", ""))
    elif plat == Platform.WINDOWS:
        root = result.get("QT_WINDOWS_ROOT", defaults.get("QT_WINDOWS_ROOT", ""))
    else:
        root = result.get("QT_ROOT", defaults.get("QT_ROOT", ""))

    if root:
        result["Qt6_DIR"] = f"{root}/lib/cmake/Qt6"
        result["CMAKE_PREFIX_PATH"] = root


_ANDROID_ABI_VARS = (
    "QT_ANDROID_ARM64_ROOT",
    "QT_ANDROID_ARMV7_ROOT",
    "QT_ANDROID_X86_64_ROOT",
    "QT_ANDROID_X86_ROOT",
)


def has_android_qt(
    result: dict[str, str],
    defaults: dict[str, str],
) -> bool:
    return any(
        result.get(v) or defaults.get(v)
        for v in _ANDROID_ABI_VARS
    )


def build_emit_sections(
    plat: Platform,
    result: dict[str, str],
    defaults: dict[str, str],
) -> list[Section]:
    """Return sections in the order they should appear in .env.local."""
    sections: list[Section] = []

    if plat == Platform.LINUX:
        qt_vars = ["QT_LINUX_ROOT", "Qt6_DIR", "CMAKE_PREFIX_PATH", "QT_HOST_ROOT"]
    elif plat == Platform.DARWIN:
        qt_vars = ["QT_MACOS_ROOT", "QT_IOS_ROOT", "Qt6_DIR", "CMAKE_PREFIX_PATH", "QT_HOST_ROOT"]
    elif plat == Platform.WINDOWS:
        qt_vars = ["QT_WINDOWS_ROOT", "Qt6_DIR", "CMAKE_PREFIX_PATH", "QT_HOST_ROOT"]
    else:
        qt_vars = ["QT_ROOT", "Qt6_DIR", "CMAKE_PREFIX_PATH"]

    sections.append(Section("Qt SDK Paths", [EnvVar(v, "") for v in qt_vars]))

    sections.append(Section("Android Qt SDK", [
        EnvVar(v, "") for v in _ANDROID_ABI_VARS
    ]))

    if plat == Platform.DARWIN:
        sections.append(Section("macOS Signing", [
            EnvVar(v, "") for v in (
                "MACOS_APP_SIGN_IDENTITY", "MACOS_DMG_SIGN_IDENTITY",
                "MACOS_NOTARY_KEYCHAIN_PROFILE",
            )
        ]))
        sections.append(Section("App Store", [
            EnvVar(v, "") for v in (
                "APPLE_DEVELOPMENT_TEAM", "MACOS_APP_STORE_PROVISIONING_PROFILE",
                "ASC_API_KEY_ID", "ASC_API_ISSUER_ID",
            )
        ]))
        sections.append(Section("iOS Signing", [
            EnvVar("IOS_PROVISIONING_PROFILE", ""),
        ]))

    if plat == Platform.LINUX:
        sections.append(Section("Linux Signing", [
            EnvVar("GPG_KEY_ID", ""),
        ]))

    if has_android_qt(result, defaults):
        sections.append(Section("Android SDK", [
            EnvVar(v, "") for v in ("ANDROID_SDK_ROOT", "ANDROID_NDK_ROOT", "JAVA_HOME")
        ]))
        sections.append(Section("Android Signing", [
            EnvVar(v, "") for v in (
                "ANDROID_KEYSTORE_PATH", "ANDROID_KEYSTORE_PASSWORD",
                "ANDROID_KEY_ALIAS", "ANDROID_KEY_PASSWORD",
            )
        ]))
        sections.append(Section("Google Play Upload", [
            EnvVar(v, "") for v in (
                "ANDROID_PLAY_SERVICE_ACCOUNT_FILE",
                "ANDROID_PLAY_TRACK", "ANDROID_PLAY_RELEASE_STATUS",
            )
        ]))

    return sections
