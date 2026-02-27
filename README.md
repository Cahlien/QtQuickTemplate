# QtQuickTemplate

A cross-platform **[Qt 6](https://www.qt.io/) / [Qt Quick (QML)](https://doc.qt.io/qt-6/qtquick-index.html)** starter repo that aims to be "just enough structure" to begin a real app:

- A clean QML app shell with **portrait + landscape** layouts and a C++ navigation controller singleton.
- A centralized **Theme** singleton (design tokens) and a custom **[Qt Quick Controls 2](https://doc.qt.io/qt-6/qtquickcontrols-index.html) style** (`AppStyle`), styled from [crowell.dev](https://www.crowell.dev).
- A place for reusable native/C++ code (including a sample library that exports a **C++20 module** when supported, with a header-based fallback).
- [CMake](https://cmake.org/) build system with platform packaging pipelines for **iOS, macOS, Android, Linux, and Windows**.
- C++ dependencies managed via [Conan 2](https://conan.io/) with a workspace layout.
- Unit tests ([Qt Test](https://doc.qt.io/qt-6/qttest-index.html), [Qt Quick Test](https://doc.qt.io/qt-6/qtquicktest-index.html)), UI tests ([Spix](https://github.com/faaxm/spix)), and integration tests ([pytest](https://docs.pytest.org/)).
- Optional **[QDoc](https://doc.qt.io/qt-6/qdoc-index.html)** targets for documentation generation.

> Maintained by [Matthew Crowell](https://www.crowell.dev) / [Confederated Technologies, Inc.](https://confederatedtechnologies.com)

---

## Getting Started

### 1. Bootstrap the development environment

Run the bootstrap script once to install [uv](https://docs.astral.sh/uv/), download the pinned CPython (from `.python-version`), and create an isolated `.venv/` with [cmake](https://cmake.org/), [conan](https://conan.io/), [pytest](https://docs.pytest.org/), and all Python-based build/test tools at pinned versions:

```bash
./tools/bootstrap.sh       # macOS / Linux
.\tools\bootstrap.ps1      # Windows
```

On Linux the script also downloads the [linuxdeploy](https://github.com/linuxdeploy/linuxdeploy) AppImage toolchain. Both platforms install Google's [bundletool](https://github.com/google/bundletool) for Android builds.

### 2. Configure your project identity

Bootstrap automatically runs `tools/devcro.py`, which prompts you to personalize the template:

```
=== Project Configuration ===

  Application name [QtQuick Template]:
  Package name (e.g. com.example.myapp) [dev.crowell.qtquicktemplate]:
  Version [0.1.0]:
```

The orchestrator:
- Renames all package identifiers project-wide (Java/Kotlin packages, QML module URIs, bundle IDs, CMake variables, etc.) via `tools/configure_package.py`. The CamelCase identifier (e.g. `QtQuickTemplate`) is derived from the name by stripping spaces.
- Propagates the **name** to the window title (`Main.qml`), Linux desktop entry, AppStream metainfo, and Windows version resource.
- Propagates the **version** to `CMakeLists.txt`, `conanfile.py`, `pyproject.toml`, and all library recipes.
- Records the result in `devcro.toml` and sets `bootstrapped = true`.

To accept defaults non-interactively (useful in CI): `python tools/devcro.py --yes`

### 3. `devcro.toml` — project identity file

```toml
[application]
name = "QtQuick Template"
description = "..."
version = "0.1.0"
build_number = 1

[config]
bootstrapped = false
package_name = "dev.crowell.qtquicktemplate"
```

| Field | Purpose |
|-------|---------|
| `name` | Human-readable application name; CamelCase form (for CMake, Conan, file names) is derived by stripping spaces |
| `version` | Semantic version propagated to all version-bearing files |
| `package_name` | Reverse-domain package ID (Android, Linux, Apple bundle ID) |
| `bootstrapped` | Set to `true` after first-time setup; re-runs only propagate version |

### 4. Configure environment (Qt SDK paths & signing)

After bootstrapping, set up Qt SDK paths and platform signing credentials:

```bash
./tools/uv run python tools/configure_env.py       # macOS / Linux
.\tools\run.ps1 python tools/configure_env.py      # Windows
```

This creates `.env.local` (gitignored) with your settings. See [Environment Variables](#environment-variables) for the full list.

### 5. Build

Run tools with `./tools/run` (a thin wrapper that loads `.env` + `.env.local` before calling `uv run`):

```bash
./tools/run cmake -S . -B build/linux-release -DCMAKE_BUILD_TYPE=Release
./tools/run cmake --build build/linux-release -j
```

Or activate the venv directly:

```bash
source .venv/bin/activate   # macOS / Linux
.venv\Scripts\Activate.ps1  # Windows
cmake -S . -B build/linux-release -DCMAKE_BUILD_TYPE=Release
```

> **IDE users:** Point your IDE's CMake executable to `.venv/bin/cmake` (macOS/Linux) or `.venv\Scripts\cmake.exe` (Windows) to use the pinned version.

---

## What you get out of the box

### UI & QML architecture
- `Main.qml` is the `ApplicationWindow` entry point.
- A C++ `NavigationController` singleton manages both overlay pages (via `StackView`) and content pages (via `Loader`).
- Two layout templates:
  - `MainPortraitLayout.qml` (header -> content -> footer)
  - `MainLandscapeLayout.qml` (side column for header/footer + content on the right)
- A sample set of pages (`Readme`, `StyleShowcase`, `License`) and simple `Header`/`Footer` components.

### Navigation architecture
The `NavigationController` maintains a single back stack of lightweight entries (`url`, `props`, `showChrome`) and exposes a small API used by QML:

- `push(url, props, showChrome)` adds a new entry.
- `replace(url, props, showChrome)` replaces the current entry without touching history.
- `pop()` restores the previous entry, or emits `backAtRoot()` when history is empty.
- `currentUrl`, `currentProps`, and `currentShowChrome` drive declarative `Loader` updates.

Back handling and app minimization are split cleanly:

- Android 13+: system back gesture enters C++ via JNI and queues `NavigationController.pop()` onto the Qt thread.
- `NavigationController::minimizeApp()` now lives in `navigation_controller.cpp` with `#ifdef`-guarded platform behavior (Android moves task to back, other platforms no-op).

### Styling
- `AppTheme` module: `Theme.qml` singleton holds colors, typography, spacing, radii, animations, etc.
- `AppStyle` module: a custom Qt Quick Controls 2 style that overrides common controls (Button, TextField, etc.).
- Style selection happens in C++ before QML loads:
  - `QQuickStyle::setStyle("AppStyle")`
  - fallback style: `"Basic"`

### Native/C++ structure
- `app/src/main/common/` holds the application entry point and shared C++ code.
- `app/include/main/common/` holds the public headers for that code.
- `app/src/main/common/navigation/` contains the `NavigationController` implementation.
- Platform specialization lives next to the app:
  - `app/src/main/android/` contains Android-specific C++ glue (JNI back gesture + startup integration).

### Build/CMake architecture
- Root `CMakeLists.txt` is a workspace coordinator — it calls `configure_project()` then adds `app/` as the sole subdirectory.
- `app/CMakeLists.txt` declares `project(QtQuickTemplate VERSION 0.2.0)`, adds `app/libs/`, and calls `configure_main_app()`.
- Toolchain logic is centralized under `cmake/toolchain/`:
  - `CompilerSettings.cmake` sets language/toolchain defaults (project default is C++23).
  - `CxxModules.cmake` detects whether C++ modules are supported for the active compiler + generator + platform.
  - `ClangScanDeps.cmake` configures `clang-scan-deps` only where needed (disabled on Apple targets).
- Deploy modules live in `cmake/deploy/` organized by platform subdirectory, with custom build targets that chain together.
- Shared library helper macros live in `cmake/libs/LibraryCommon.cmake` to keep per-library `CMakeLists.txt` readable.

### Testing
- C++ unit tests use [Qt Test](https://doc.qt.io/qt-6/qttest-index.html); QML tests use [Qt Quick Test](https://doc.qt.io/qt-6/qtquicktest-index.html). Gated by `QTQUICKTEMPLATE_ENABLE_TESTING` (ON by default on desktop).
- UI tests use [Spix](https://github.com/faaxm/spix) (fetched via [FetchContent](https://cmake.org/cmake/help/latest/module/FetchContent.html)) to simulate user interactions headlessly.
- Integration tests (Apple deploy pipelines) use [pytest](https://docs.pytest.org/).

### Platform bootstrapping (Android splash)
- Android uses a `QtActivity` subclass that shows a lightweight overlay and fades it out when Qt renders its first frame.
- C++ calls into the Android activity on the first rendered frame (`onFirstFrame(...)`).

### Docs
- A `docs` target generates HTML documentation via [QDoc](https://doc.qt.io/qt-6/qdoc-index.html) (if `qdoc` is found).
- The `app/libs/helloworld` sample library also has its own QDoc target.

---

## Repository layout

```text
.
├── .env                               # tracked defaults (ANDROID_PLAY_TRACK, ANDROID_PLAY_RELEASE_STATUS)
├── .env.local                         # gitignored developer overrides (Qt paths, signing credentials)
├── .python-version                    # pinned CPython 3.14t (freethreaded) for uv
├── CMakeLists.txt                     # workspace coordinator; no VERSION (app/ owns it)
├── CMakePresets.json                  # platform build presets (iOS, macOS, etc.)
├── LICENSE
├── conanfile.py                       # workspace version-authority recipe (single-version rule)
├── conanws.py                         # Conan workspace definition; lists monorepo products
├── devcro.toml                        # project identity file (name, version, package)
├── pyproject.toml                     # workspace Python metadata and dependency declarations
├── uv.lock                            # cross-platform dependency lockfile
│
├── app/                               # main application
│   ├── CMakeLists.txt                 # project() with VERSION, adds libs/ subdirectory
│   ├── conanfile.py                   # app-level Conan recipe
│   ├── pyproject.toml                 # app-level pytest configuration
│   │
│   ├── include/                       # public C++ headers
│   ├── src/                           # C++ source (main/common/, main/android/)
│   ├── qml/                           # QML files (atoms, molecules, organisms, templates, pages)
│   ├── platforms/                     # platform resources (ios, macos, android, linux, windows)
│   ├── libs/                          # project-internal libraries (appstyle, apptheme, helloworld)
│   └── test/                          # unit (cpp, qml), ui (spix), integration (pytest)
│
├── cmake/                             # CMake modules
│   ├── ProjectSetup.cmake             # compiler settings, Conan, Qt discovery
│   ├── MainApp.cmake                  # executable, QML modules, deploy wiring
│   ├── deploy/                        # platform packaging pipelines
│   ├── testing/                       # test infrastructure (TestTargets, FetchSpix)
│   ├── toolchain/                     # CompilerSettings, CxxModules, ClangScanDeps
│   ├── libs/                          # LibraryCommon.cmake helpers
│   └── qt/                            # QmlModule, QtProject
│
└── tools/                             # developer tooling
    ├── bootstrap.sh / bootstrap.ps1   # dev environment setup
    ├── devcro.py                      # project identity orchestrator
    ├── configure_package.py           # project renaming/repackaging engine
    ├── configure_env.py               # interactive Qt SDK + signing config wizard
    ├── configure_env/                 # configure_env Python package
    ├── run / run.ps1                  # env-aware wrapper: loads .env/.env.local before running tools
    └── configure_env.sh / .ps1        # platform env configuration helpers
```

---

## Build prerequisites

- **[Qt 6.10+](https://www.qt.io/download)** (Core, Quick, QuickControls2, Qml)
- **[CMake 4.2.1+](https://cmake.org/download/)**
- A C++23-capable compiler
- Optional module path requirements:
  - On supported non-Apple toolchains/generators, `helloworld` exports a C++20 module.
  - On Apple targets (and unsupported generators/toolchains), the app automatically uses the header/library path.
  - If using Clang with modules enabled, `clang-scan-deps` must be available (the project attempts to locate it automatically, including Android NDK hints).

All of the above (except Qt and a system compiler) are installed by the bootstrap script.

---

## Environment Variables

This project uses environment variables for Qt SDK paths and platform signing credentials. Variables can be set in two ways:

1. **`.env.local`** (recommended, gitignored) — per-developer overrides
2. **`CMakeUserPresets.json`** — per-preset environment (Apple platforms)

Both are gitignored. The `./tools/run` wrapper loads `.env` and `.env.local` automatically.

### Qt SDK Paths

| Variable | Platform | Example |
|----------|----------|---------|
| `QT_MACOS_ROOT` | macOS | `~/Qt/6.10.2/macos` |
| `QT_IOS_ROOT` | iOS | `~/Qt/6.10.2/ios` |
| `QT_LINUX_ROOT` | Linux | `~/Qt/6.10.2/gcc_64` |
| `QT_ANDROID_ROOT` | Android | `~/Qt/6.10.2/android_arm64_v8a` |
| `QT_HOST_ROOT` | Cross-compile | `~/Qt/6.10.2/macos` |
| `Qt6_DIR` | Derived | `${QT_MACOS_ROOT}/lib/cmake/Qt6` |

### Apple Code Signing

| Variable | Used By | Description |
|----------|---------|-------------|
| `APPLE_DEVELOPMENT_TEAM` | iOS, macOS | 10-character Team ID |
| `MACOS_APP_SIGN_IDENTITY` | macOS DMG | Signing identity for app bundle (e.g., `Developer ID Application: Your Name (TEAMID)`) |
| `MACOS_DMG_SIGN_IDENTITY` | macOS DMG | Signing identity for DMG |
| `MACOS_NOTARY_KEYCHAIN_PROFILE` | macOS DMG | Keychain profile for `notarytool` |
| `MACOS_APP_STORE_PROVISIONING_PROFILE` | macOS App Store | Provisioning profile name |
| `IOS_PROVISIONING_PROFILE` | iOS | Provisioning profile name |
| `ASC_API_KEY_ID` | iOS, macOS | App Store Connect API key ID |
| `ASC_API_ISSUER_ID` | iOS, macOS | App Store Connect API issuer UUID |

### Android Signing & Upload

| Variable | Used By | Description |
|----------|---------|-------------|
| `ANDROID_KEYSTORE_PATH` | Android signing | Path to keystore file |
| `ANDROID_KEYSTORE_PASSWORD` | Android signing | Keystore password |
| `ANDROID_KEY_ALIAS` | Android signing | Key alias within keystore |
| `ANDROID_KEY_PASSWORD` | Android signing | Key password |
| `ANDROID_PLAY_SERVICE_ACCOUNT_FILE` | Play upload | Path to service account JSON |
| `ANDROID_PLAY_TRACK` | Play upload | Track name (default: `internal`) |
| `ANDROID_PLAY_RELEASE_STATUS` | Play upload | Release status (default: `completed`) |

### Linux Signing

| Variable | Used By | Description |
|----------|---------|-------------|
| `GPG_KEY_ID` | AppImage | GPG key ID for signing |

---

## Linux: build, package, sign

### Build (local desktop binary)

```bash
./tools/run cmake -S . -B build/linux-debug -DCMAKE_BUILD_TYPE=Debug
./tools/run cmake --build build/linux-debug -j
```

For release builds:

```bash
./tools/run cmake -S . -B build/linux-release -DCMAKE_BUILD_TYPE=Release
./tools/run cmake --build build/linux-release -j
```

Run on Linux:

```bash
./build/linux-debug/appQtQuickTemplate
```

### Build with Conan (optional)

```bash
./tools/run conan install . -s build_type=Debug --build=missing -of build/conan
./tools/run cmake -S . -B build/linux-debug -DCMAKE_TOOLCHAIN_FILE=build/conan/conan_toolchain.cmake
./tools/run cmake --build build/linux-debug -j
```

### Package (AppImage)

AppImage packaging is provided by `cmake/deploy/linux/LinuxPackage.cmake` and requires:

- [`linuxdeploy`](https://github.com/linuxdeploy/linuxdeploy)
- [`linuxdeploy-plugin-qt`](https://github.com/linuxdeploy/linuxdeploy-plugin-qt)
- [`linuxdeploy-plugin-appimage`](https://github.com/linuxdeploy/linuxdeploy-plugin-appimage)

If they are installed in `~/applications`, `~/.local/bin`, or `/usr/local/bin`, CMake auto-detects them and enables the `AppImage` target.

```bash
./tools/run cmake -S . -B build/linux-release -DCMAKE_BUILD_TYPE=Release
./tools/run cmake --build build/linux-release --target AppImage -j
```

Output:

```text
build/linux-release/AppImageBuild/QtQuickTemplate-<version>-x86_64.AppImage
```

### Sign (AppImage)

AppImage signing is integrated into the same `AppImage` target. Provide a key ID at configure time:

```bash
./tools/run cmake -S . -B build/linux-release \
  -DCMAKE_BUILD_TYPE=Release \
  -DGPG_KEY_ID=<YOUR_KEY_ID>
./tools/run cmake --build build/linux-release --target AppImage -j
```

If `GPG_KEY_ID` is not set, the AppImage plugin uses your default GPG secret key.

### Verify (AppImage)

After packaging, verify the embedded signature with the `validate` tool from AppImageUpdate:

```bash
wget -O validate https://github.com/AppImageCommunity/AppImageUpdate/releases/download/continuous/validate-x86_64.AppImage
chmod +x validate
./validate ./build/linux-release/AppImageBuild/QtQuickTemplate-<version>-x86_64.AppImage
```

---

## Android: build, package, sign

This repo is configured for [Qt Android deployment](https://doc.qt.io/qt-6/android.html) (`QT_ANDROID_PACKAGE_SOURCE_DIR=app/platforms/android`).

### Build

Use a Qt Android kit in [Qt Creator](https://www.qt.io/product/development-tools) (recommended). The build also regenerates:

- `app/platforms/android/version.properties`

from project version values via the `GenerateAndroidVersion` CMake target.

If you need to change app identifiers or Android metadata, start here:

- `app/platforms/android/build.gradle` (namespace)
- `app/platforms/android/src/main/kotlin/.../MainActivity.kt` (package)
- `app/platforms/android/AndroidManifest.xml`

### Package

From Qt Creator, build with your Android kit using Debug/Release as needed.

From command line, use the generated Gradle project in your Android build folder (usually `<build-dir>/android-build`):

```bash
./gradlew assembleDebug
./gradlew assembleRelease
./gradlew bundleRelease
```

Typical outputs:

- APKs: `android-build/build/outputs/apk/<variant>/`
- AAB: `android-build/build/outputs/bundle/release/`

### Sign

Create a keystore (one-time):

```bash
keytool -genkeypair -v -keystore release.keystore -alias app-release -keyalg RSA -keysize 4096 -validity 10000
```

#### Sign APK manually

```bash
zipalign -p 4 app-release-unsigned.apk app-release-aligned.apk
apksigner sign --ks release.keystore --ks-key-alias app-release app-release-aligned.apk
apksigner verify --verbose --print-certs app-release-aligned.apk
```

#### Sign AAB manually

```bash
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
  -keystore release.keystore app-release.aab app-release
jarsigner -verify -verbose app-release.aab
```

`zipalign` and `apksigner` are in Android SDK Build-Tools. Configure your shell `PATH` or use absolute paths.

---

## iOS: build, archive, sign, export, upload (App Store)

The full pipeline — build -> archive -> sign -> export IPA -> verify -> upload to App Store Connect — runs with a single CMake build preset.

### Prerequisites

- **Xcode** with command-line tools (`xcode-select --install`)
- **Qt 6.10+** for iOS (e.g. `~/Qt/6.10.2/ios`)
- An **Apple Developer** account with:
  - "Apple Distribution" certificate in your Keychain
  - App Store distribution provisioning profile for your bundle ID
  - App Store Connect API key (`.p8` file in `~/.appstoreconnect/private_keys/`)

### Setup

`CMakeUserPresets.json` is gitignored. Create it at the repo root with your local signing details:

```json
{
    "version": 6,
    "configurePresets": [
        {
            "name": "ios-release-local",
            "inherits": "ios-release",
            "environment": {
                "QT_IOS_ROOT": "/path/to/Qt/6.10.2/ios",
                "APPLE_DEVELOPMENT_TEAM": "<10-char Team ID>",
                "IOS_PROVISIONING_PROFILE": "<Provisioning profile name>",
                "ASC_API_KEY_ID": "<Key ID, e.g. ABCD123456>",
                "ASC_API_ISSUER_ID": "<Issuer UUID>"
            },
            "cacheVariables": {
                "CMAKE_OSX_ARCHITECTURES": "arm64",
                "CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY": "Apple Distribution"
            }
        }
    ],
    "buildPresets": [
        {
            "name": "ios-app-local",
            "inherits": "ios-app",
            "configurePreset": "ios-release-local"
        },
        {
            "name": "ios-distributable-local",
            "inherits": "ios-distributable",
            "configurePreset": "ios-release-local"
        }
    ]
}
```

### Build & deploy

```bash
./tools/run cmake --preset ios-release-local               # Configure
./tools/run cmake --build --preset ios-app-local            # Build only
./tools/run cmake --build --preset ios-distributable-local  # Full pipeline
```

---

## macOS: two distribution channels

| Channel | Format | Signing | Notarization |
|---------|--------|---------|--------------|
| **Direct distribution** | DMG | Developer ID | Yes (notarytool) |
| **App Store** | PKG | Apple Distribution | No (Apple reviews) |

---

## macOS — Direct distribution (DMG)

### Setup

Add a macOS DMG preset to `CMakeUserPresets.json`:

```json
{
    "name": "macos-release-local",
    "inherits": "macos-release",
    "environment": {
        "QT_MACOS_ROOT": "/path/to/Qt/6.10.2/macos",
        "APPLE_DEVELOPMENT_TEAM": "<Team ID>",
        "MACOS_APP_SIGN_IDENTITY": "Developer ID Application: Your Name (TEAMID)",
        "MACOS_DMG_SIGN_IDENTITY": "Developer ID Application: Your Name (TEAMID)",
        "MACOS_NOTARY_KEYCHAIN_PROFILE": "<notarytool profile name>"
    }
}
```

### Build & deploy

```bash
./tools/run cmake --preset macos-release-local                    # Configure
./tools/run cmake --build --preset macos-app-local                # Build only
./tools/run cmake --build --preset macos-distributable-local      # Full: build -> macdeployqt -> DMG -> notarize -> staple -> verify
```

---

## macOS — App Store distribution (PKG)

### Setup

Add a macOS App Store preset to `CMakeUserPresets.json`:

```json
{
    "name": "macos-appstore-local",
    "inherits": "macos-appstore",
    "environment": {
        "QT_MACOS_ROOT": "/path/to/Qt/6.10.2/macos",
        "APPLE_DEVELOPMENT_TEAM": "<Team ID>",
        "MACOS_APP_STORE_PROVISIONING_PROFILE": "<Profile name>",
        "ASC_API_KEY_ID": "<Key ID>",
        "ASC_API_ISSUER_ID": "<Issuer UUID>"
    }
}
```

### Build & deploy

```bash
./tools/run cmake --preset macos-appstore-local                              # Configure
./tools/run cmake --build --preset macos-appstore-distributable-local        # Full: build -> archive -> export PKG -> verify -> upload
```

---

## Testing

C++ unit tests use [Qt Test](https://doc.qt.io/qt-6/qttest-index.html); QML tests use [Qt Quick Test](https://doc.qt.io/qt-6/qtquicktest-index.html). Gated by `QTQUICKTEMPLATE_ENABLE_TESTING` (ON by default on desktop, OFF on iOS/Android).

```bash
# Run all tests via CTest
./tools/run ctest --preset linux-tests

# Run individual tests
./tools/run ctest --preset linux-tests -R tst_helloworld      # HelloWorld C++ tests
./tools/run ctest --preset linux-tests -R tst_cpp             # NavigationController C++ tests
./tools/run ctest --preset linux-tests -R tst_qml_apptheme    # AppTheme QML tests
./tools/run ctest --preset linux-tests -R tst_qml_appstyle    # AppStyle QML tests
./tools/run ctest --preset linux-tests -R tst_qml_navigation  # Navigation QML tests
./tools/run ctest --preset linux-tests -R tst_ui_navigation   # Spix UI navigation test

# Disable testing (e.g. for mobile builds)
./tools/run cmake -S . -B build/no-tests -DQTQUICKTEMPLATE_ENABLE_TESTING=OFF
```

### Integration tests (Apple deploy pipelines, pytest, macOS only)

```bash
./tools/uv run pytest -c app/pyproject.toml                    # 0 tests (all integration, excluded by default)
./tools/uv run pytest -c app/pyproject.toml -m integration     # all integration tests
./tools/uv run pytest -c app/pyproject.toml -m ios             # iOS pipeline only
./tools/uv run pytest -c app/pyproject.toml -m macos_dmg       # macOS DMG pipeline only
./tools/uv run pytest -c app/pyproject.toml -m macos_appstore  # macOS App Store pipeline only
```

---

## QML modules & resource layout

Three QML modules, each a separate CMake target:

| Module URI | Source | Description |
|------------|--------|-------------|
| `dev.crowell.QtQuickTemplate` | `app/qml/` | Main app QML (pages, organisms, templates) |
| `dev.crowell.AppTheme` | `app/libs/apptheme/qml/` | `Theme.qml` singleton (design tokens) |
| `dev.crowell.AppStyle` | `app/libs/appstyle/qml/` | Custom Qt Quick Controls 2 style |

QML files use `QT_RESOURCE_ALIAS` for flattened resource paths (e.g., `app/qml/pages/Readme.qml` -> `pages/Readme.qml`).

---

## Documentation (QDoc)

```bash
./tools/run cmake --build build/linux-release --target docs       # main app docs
./tools/run cmake --build build/linux-release --target helloworld_docs  # library docs
```

Requires `qdoc` on `PATH` (comes with Qt).

---

## Discovering build targets (`help-targets`)

Every platform defines a `help-targets` meta-target that lists available build targets with descriptions:

```bash
./tools/run cmake --build <build-dir> --target help-targets
```

---

## Style notes

See `app/libs/appstyle/README.md` for a deeper dive into the Theme/AppStyle approach and how the controls are overridden.

---

## Contributing

PRs welcome — keep changes small, keep the template sharp, and try not to introduce "magic" unless it removes more pain than it adds.

---

## AI Use Policy

AI-assisted tooling is permitted throughout the entire workflow when contributing to this repository — from initial exploration and prototyping through implementation, testing, and review — provided the following conditions are met:

1. **Human accountability.** Every contribution must have an associated human contributor who is responsible for reviewing and maintaining any AI-generated or AI-assisted code and who is accountable for its correctness, security, and adherence to project conventions.

2. **Active monitoring.** AI output must be actively monitored and reviewed by the contributor before submission. Do not submit AI-generated changes without reading, understanding, and verifying them.

3. **Transparency.** Contributors should note AI involvement in commit messages or PR descriptions when AI played a substantial role (e.g., `Co-Authored-By` trailers).

### Ideal tasks for AI assistance

AI tooling is especially well-suited for:

- **Deduplication** — identifying and consolidating repeated logic across the codebase
- **Error and edge case checking** — surfacing unhandled conditions, boundary issues, and failure modes
- **Documentation** — generating and maintaining doc comments, README sections, and inline explanations
- **Enforcing style consistency** — applying project conventions (C++23 idioms, QML patterns, CMake module structure) uniformly
- **Code review** — catching bugs, suggesting improvements, and verifying cross-platform correctness

### AI agent configuration

This repository includes instruction files for several AI coding agents:

| File | Agent(s) |
|------|----------|
| `CLAUDE.md` | [Claude Code](https://docs.anthropic.com/en/docs/claude-code) |
| `AGENTS.md` | [OpenAI Codex](https://openai.com/index/openai-codex/), [OpenCode](https://github.com/opencode-ai/opencode) |
| `GEMINI.md` | [Google Gemini CLI](https://github.com/google-gemini/gemini-cli) |
| `.github/copilot-instructions.md` | [GitHub Copilot](https://github.com/features/copilot) |
| `.junie/guidelines.md` | [JetBrains Junie](https://www.jetbrains.com/junie/) |

These files contain project architecture context, build commands, and conventions to help AI agents produce correct, idiomatic contributions. Each agent is encouraged to decompose complex tasks into focused subtasks and to read existing code before proposing modifications.
