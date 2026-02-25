# QtQuickTemplate

A cross-platform **Qt 6 / Qt Quick (QML)** starter repo that aims to be "just enough structure" to begin a real app:

- A clean QML app shell with **portrait + landscape** layouts and a C++ navigation controller singleton.
- A centralized **Theme** singleton (design tokens) and a custom **Qt Quick Controls 2 style** (`AppStyle`).
- A place for reusable native/C++ code (including a sample library that exports a **C++20 module** when supported, with a header-based fallback).
- Platform packaging hooks for **Android, Windows, macOS, and Linux**.
- Optional **QDoc** targets for documentation generation.

---

## What you get out of the box

### UI & QML architecture
- `Main.qml` is the `ApplicationWindow` entry point.
- A C++ `NavigationController` singleton manages both overlay pages (via `StackView`) and content pages (via `Loader`).
- Two layout templates:
  - `MainPortraitLayout.qml` (header → content → footer)
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
- `src/main/common/` holds the application entry point and shared C++ code.
- `include/main/common/` holds the public headers for that code.
- `src/main/common/navigation/` contains the `NavigationController` implementation.
- Platform specialization lives next to the app:
  - `src/main/android/` contains Android-specific C++ glue (JNI back gesture + startup integration).

### Build/CMake architecture
- Root `CMakeLists.txt` delegates setup to focused modules under `cmake/`.
- Toolchain logic is centralized under `cmake/toolchain/`:
  - `CompilerSettings.cmake` sets language/toolchain defaults (project default is C++23).
  - `CxxModules.cmake` detects whether C++ modules are supported for the active compiler + generator + platform.
  - `ClangScanDeps.cmake` configures `clang-scan-deps` only where needed (disabled on Apple targets).
- Shared library helper chunks live in `cmake/libs/LibraryCommon.cmake` to keep per-library `CMakeLists.txt` readable.

### Platform bootstrapping (Android splash)
- Android uses a `QtActivity` subclass that shows a lightweight overlay and fades it out when Qt renders its first frame.
- C++ calls into the Android activity on the first rendered frame (`onFirstFrame(...)`).

### Docs
- A `docs` target generates HTML documentation via QDoc (if `qdoc` is found).
- The `libs/helloworld` sample library also has its own QDoc target.

---

## Repository layout

```text
.
├── .env                                  # tracked defaults (ANDROID_PLAY_TRACK, ANDROID_PLAY_RELEASE_STATUS)
├── .env.local                            # gitignored developer overrides (Qt paths, signing credentials)
├── .python-version                     # pinned CPython 3.14t (freethreaded) for uv
├── CMakeLists.txt                      # minimal root; delegates to cmake/ modules
├── CMakePresets.json                   # platform build presets (iOS, macOS, etc.)
├── LICENSE
├── conanfile.py
├── pyproject.toml                      # Python deps and tool config
├── uv.lock                            # cross-platform dependency lockfile
│
├── cmake/
│   ├── MainApp.cmake                   # executable, QML modules, deploy wiring
│   ├── ProjectSetup.cmake              # compiler settings, Conan, Qt discovery
│   │
│   ├── deploy/                         # platform packaging pipelines
│   │   ├── DeployPipelines.cmake       # platform-conditional dispatcher
│   │   ├── ReleaseDistributables.cmake # meta-targets aggregating pipelines
│   │   ├── Install.cmake               # cross-platform install rules
│   │   ├── GenerateVersion.cmake       # git-derived build numbers
│   │   ├── VersionTarget.cmake         # shared version target helper
│   │   │
│   │   ├── android/
│   │   │   ├── AndroidBuild.cmake      # AndroidAAB / AndroidAPK / SignAndroidAAB
│   │   │   ├── AndroidVerify.cmake     # VerifyAndroidAAB / VerifyAndroidAPK
│   │   │   ├── AndroidUpload.cmake     # UploadAndroidPlay (Google Play)
│   │   │   ├── AndroidVersion.cmake    # GenerateAndroidVersion target
│   │   │   ├── AndroidHelpTargets.cmake # unconditional Android help registration
│   │   │   ├── GenerateVersion.cmake   # -P script for version.properties
│   │   │   ├── VerifyAab.cmake         # -P script for AAB verification
│   │   │   └── VerifyApk.cmake         # -P script for APK verification
│   │   │
│   │   ├── apple/                      # shared iOS + macOS helpers
│   │   │   ├── AppleCodeSigning.cmake  # release code signing config
│   │   │   ├── ArtifactVerify.cmake    # unified artifact verification
│   │   │   ├── AscUpload.cmake         # unified App Store Connect upload
│   │   │   ├── FindMacDeployQt.cmake   # macdeployqt discovery
│   │   │   ├── XcodeExport.cmake       # unified xcodebuild -exportArchive
│   │   │   ├── UploadAsc.cmake         # -P script for ASC upload
│   │   │   └── VerifyArtifact.cmake    # -P script for artifact verification
│   │   │
│   │   ├── ios/
│   │   │   ├── IOSBuild.cmake          # IOSArchive target
│   │   │   ├── IOSResources.cmake      # asset catalog + launch screen
│   │   │   └── GenerateLaunchScreen.cmake
│   │   │
│   │   ├── linux/
│   │   │   ├── LinuxPackage.cmake      # AppImage target
│   │   │   ├── StageWaylandSupport.cmake
│   │   │   └── VerifyWaylandDeps.cmake
│   │   │
│   │   └── macos/
│   │       ├── MacOSBuild.cmake        # MacDeployQt target
│   │       ├── MacOSPackage.cmake      # DMG target
│   │       ├── MacOSSign.cmake         # NotarizeMacOS target
│   │       ├── MacOSVerify.cmake       # VerifyMacOSPackage target
│   │       ├── MacOSAppStoreBuild.cmake # MacAppStoreArchive target
│   │       ├── Notarize.cmake          # -P script for notarization
│   │       ├── PatchArchiveInfo.cmake  # -P script for archive patching
│   │       ├── RunMacDeployQt.cmake    # -P script for macdeployqt
│   │       ├── SignDmg.cmake           # -P script for DMG signing
│   │       └── VerifyPackage.cmake     # -P script for package verification
│   │
│   ├── docs/
│   │   └── QDoc.cmake                  # docs target (QDoc documentation)
│   │
│   ├── help/
│   │   ├── HelpTargets.cmake           # register_help_target() + finalize
│   │   └── PrintHelp.cmake             # -P script for formatted help output
│   │
│   ├── integration/
│   │   └── Conan.cmake                 # Conan package manager integration
│   │
│   ├── libs/
│   │   └── LibraryCommon.cmake         # add_portable_cpp_library() helpers
│   │
│   ├── platform/
│   │   └── PlatformSources.cmake       # platform-specific source selection
│   │
│   ├── qt/
│   │   ├── QmlModule.cmake             # QML module registration
│   │   └── QtProject.cmake             # Qt discovery + FFmpeg workaround
│   │
│   └── toolchain/
│       ├── CompilerSettings.cmake      # C++23, warnings, IPO
│       ├── CxxModules.cmake            # C++20 module support detection
│       └── ClangScanDeps.cmake         # clang-scan-deps configuration
│
├── doc/
│   ├── qtquicktemplate.qdocconf
│   └── modules.qdoc
│
├── include/
│   └── main/common/
│       ├── app_info.h
│       ├── platform_init.h
│       └── navigation/
│           └── navigation_controller.h
│
├── libs/
│   ├── CMakeLists.txt                  # auto-adds child lib dirs
│   ├── appstyle/                       # custom Qt Quick Controls 2 style
│   │   ├── CMakeLists.txt
│   │   ├── README.md
│   │   └── qml/                        # Button, CheckBox, ComboBox, ...
│   ├── apptheme/                       # AppTheme singleton (design tokens)
│   │   ├── CMakeLists.txt
│   │   └── qml/Theme.qml
│   └── helloworld/                     # sample C++20 module library
│       ├── CMakeLists.txt
│       ├── helloworld.cppm
│       ├── include/helloworld.h
│       ├── src/helloworld.cpp
│       └── doc/helloworld.qdocconf
│
├── platforms/
│   ├── android/                        # Gradle project, resources, Kotlin sources
│   │   ├── AndroidManifest.xml
│   │   ├── build.gradle
│   │   ├── gradle.properties
│   │   ├── settings.gradle
│   │   ├── proguard-rules.pro
│   │   ├── gradlew / gradlew.bat
│   │   ├── gradle/                     # wrapper + version catalog
│   │   ├── res/                        # icons, splash, layouts, values
│   │   └── src/main/kotlin/            # MainActivity + extensions
│   ├── ios/                            # Info.plist, Assets.xcassets, LaunchScreen
│   ├── linux/                          # .desktop template, metainfo, icons
│   ├── macos/                          # Info.plist, entitlements, app.icns
│   └── windows/                        # app.ico, app.manifest, app.rc.in
│
├── qml/
│   ├── Main.qml                        # ApplicationWindow entry point
│   ├── atoms/                          # atomic design: smallest components
│   ├── molecules/                      # atomic design: composed atoms
│   ├── organisms/                      # composite components
│   │   ├── Header.qml
│   │   ├── Footer.qml
│   │   ├── NavBar.qml
│   │   └── NavigationStack.qml
│   ├── pages/                          # full-page views
│   │   ├── BasePage.qml
│   │   ├── License.qml
│   │   ├── Readme.qml
│   │   ├── StyleShowcase.qml
│   │   └── content/                    # page content components
│   │       ├── LicenseContent.qml
│   │       ├── ReadmeContent.qml
│   │       └── StyleShowcaseContent.qml
│   ├── scripts/                        # QML JavaScript modules
│   └── templates/                      # layout templates
│       ├── AdaptiveLayout.qml
│       ├── MainPortraitLayout.qml
│       └── MainLandscapeLayout.qml
│
├── src/
│   └── main/
│       ├── common/
│       │   ├── main.cpp                # application entry point
│       │   ├── app_info.cpp
│       │   ├── platform_init_default.cpp
│       │   └── navigation/
│       │       └── navigation_controller.cpp
│       └── android/
│           ├── android_back_handler.cpp
│           └── platform_init_android.cpp
│
├── tests/                              # pytest integration tests
│   ├── conftest.py
│   ├── test_ios_pipeline.py
│   ├── test_macos_appstore_pipeline.py
│   ├── test_macos_dmg_pipeline.py
│   └── helpers/                        # shared test utilities
│       ├── artifacts.py
│       ├── asc_api.py
│       ├── cmake.py
│       └── codesign.py
│
└── tools/                              # developer tooling
    ├── bootstrap.sh                    # dev environment setup (macOS/Linux)
    ├── bootstrap.ps1                   # dev environment setup (Windows)
    ├── configure-env.sh                # interactive Qt SDK + signing config wizard (macOS/Linux)
    ├── configure-env.ps1               # interactive Qt SDK + signing config wizard (Windows)
    ├── run                             # env-aware wrapper: loads .env/.env.local before running tools
    ├── run.ps1                         # env-aware wrapper for Windows
    └── configure_package.py            # project renaming/repackaging script
```

---

## Build prerequisites

- **Qt 6.10+** (Core, Quick, QuickControls2, Qml)
- A C++23-capable compiler
- Optional module path requirements:
  - On supported non-Apple toolchains/generators, `helloworld` exports a C++20 module.
  - On Apple targets (and unsupported generators/toolchains), the app automatically uses the header/library path.
  - If using Clang with modules enabled, `clang-scan-deps` must be available (the project attempts to locate it automatically, including Android NDK hints).

### Recommended: bootstrap script

The fastest way to get cmake, conan, pytest, and all Python-based tools at the correct versions:

```bash
./tools/bootstrap.sh       # macOS/Linux
.\tools\bootstrap.ps1      # Windows
```

This installs [uv](https://docs.astral.sh/uv/) into a project-local `tools/` directory, downloads the pinned CPython (from `.python-version`), and creates an isolated `.venv/` with all dependencies locked in `uv.lock`. Run tools with `./tools/run`:

```bash
./tools/run cmake --preset <preset>
./tools/run pytest
```

`./tools/run` is a thin wrapper around `uv run` that automatically loads environment variables from:
1. `.env` — tracked defaults (e.g., Android Play defaults)
2. `.env.local` — developer-specific overrides (gitignored)

If `.env.local` is missing and you run `cmake`, the wrapper prints a warning reminding you to run `configure-env.sh`.

Alternatively, activate the venv to put all tools on your `PATH` directly:

```bash
source .venv/bin/activate   # macOS/Linux
.venv\Scripts\Activate.ps1  # Windows
```

> **IDE users:** Activating the venv only affects your current terminal session. IDEs (Qt Creator, CLion, Xcode, Visual Studio) have their own tool discovery and will not see the activated venv. Point your IDE's CMake executable setting to `.venv/bin/cmake` (macOS/Linux) or `.venv\Scripts\cmake.exe` (Windows) to use the pinned version.

### Configure environment

After bootstrapping, set up your Qt SDK paths and platform signing credentials. You have two options:

#### Option 1: Interactive wizard (recommended)

Run the configure script to interactively prompt for your SDK paths and credentials:

```bash
./tools/configure-env.sh       # macOS/Linux
.\tools\configure-env.ps1      # Windows
```

This creates `.env.local` with your settings. The wizard:
- Detects your platform and prompts for relevant fields
- Loads existing `.env.local` values as defaults (safe to re-run)
- Validates paths exist (with a warning if missing)
- Writes organized, commented output

#### Option 2: Manual .env.local

Create `.env.local` manually with your values. See the [Environment Variables](#environment-variables) section for the full list.

### Manual alternative

If you prefer to manage tools globally:
- **CMake 3.28+**
- **Conan 2** (optional; the repo includes a `conanfile.py`)
- **Python 3.14+** with pytest for running integration tests

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

AppImage packaging is provided by `cmake/AppImage.cmake` and requires:

- `linuxdeploy`
- `linuxdeploy-plugin-qt`
- `linuxdeploy-plugin-appimage`

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

This repo is configured for Qt Android deployment (`QT_ANDROID_PACKAGE_SOURCE_DIR=platforms/android`).

### Build

Use a Qt Android kit in Qt Creator (recommended). The build also regenerates:

- `platforms/android/version.properties`

from project version values via the `GenerateAndroidVersion` CMake target.

If you need to change app identifiers or Android metadata, start here:

- `platforms/android/build.gradle` (namespace)
- `platforms/android/src/main/kotlin/.../MainActivity.kt` (package)
- `platforms/android/AndroidManifest.xml`

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

The full pipeline — build → archive → sign → export IPA → verify → upload to App Store Connect — runs with a single CMake build preset.

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
                "CMAKE_OSX_DEPLOYMENT_TARGET": "17.0",
                "QTQUICKTEMPLATE_APPLE_BUNDLE_IDENTIFIER": "com.example.yourapp"
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

**Two ways to set environment variables:**

1. **`.env.local`** (recommended) — set `QT_MACOS_ROOT`, `APPLE_DEVELOPMENT_TEAM`, `ASC_API_KEY_ID`, `ASC_API_ISSUER_ID` in `.env.local`. Run `./tools/configure-env.sh` to interactively configure.
2. **`CMakeUserPresets.json`** — set these values in the preset's `environment` block as shown above.

Both approaches work; `.env.local` is simpler for single-machine setups, while `CMakeUserPresets.json` enables per-preset configurations.

### Full pipeline (one command after first configure)

```bash
# Configure (once, or after CMake changes)
./tools/run cmake --preset ios-release-local

# Build → archive → sign → export IPA → verify → upload to App Store Connect
./tools/run cmake --build --preset ios-distributable-local
```

Output IPA: `build/Qt_6_10_2_for_iOS/ios/export/QtQuickTemplate.ipa`

### Individual targets

| Target | What it does |
|--------|-------------|
| `IOSArchive` | Runs `xcodebuild archive` with the Apple Distribution identity |
| `IOSExportIPA` | Exports the archive as a signed `.ipa` (App Store method) |
| `VerifyIOSIPA` | Confirms the `.ipa` was created successfully |
| `IOSUploadASC` | Uploads the `.ipa` to App Store Connect via `xcrun altool` |
| `ReleaseDistributableIOS` | Meta-target: runs all of the above in order |

To build without uploading:

```bash
./tools/run cmake --build --preset ios-app-local
```

### CMake cache variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM` | 10-char Team ID | (from `APPLE_DEVELOPMENT_TEAM` env) |
| `QTQUICKTEMPLATE_APPLE_BUNDLE_IDENTIFIER` | Bundle identifier | `dev.crowell.qtquicktemplate` |
| `QTQUICKTEMPLATE_IOS_PROVISIONING_PROFILE` | Provisioning profile name | (from `IOS_PROVISIONING_PROFILE` env) |
| `QTQUICKTEMPLATE_IOS_ARCHIVE_CONFIGURATION` | Xcode build configuration | `Release` |
| `QTQUICKTEMPLATE_ASC_API_KEY_ID` | App Store Connect API key ID | (from `ASC_API_KEY_ID` env) |
| `QTQUICKTEMPLATE_ASC_API_ISSUER_ID` | App Store Connect API issuer UUID | (from `ASC_API_ISSUER_ID` env) |

---

## macOS: two distribution channels

macOS has two independent pipelines sharing the same source:

| Channel | Signing | Output | Destination |
|---------|---------|--------|-------------|
| **Direct (Developer ID)** | `Developer ID Application` | Notarized `.dmg` | Your website / direct download |
| **Mac App Store** | `Apple Distribution` | Signed `.pkg` | App Store Connect |

---

## macOS — Direct distribution: build, deploy, sign, notarize, verify (DMG)

The full pipeline — build → deploy Qt frameworks → sign app → create DMG → sign DMG → notarize → staple → verify — runs with a single CMake build preset.

### Prerequisites

- **Xcode** with command-line tools (`xcode-select --install`)
- **Qt 6.10+** for macOS (e.g. `~/Qt/6.10.2/macos`)
- An **Apple Developer** account with:
  - "Developer ID Application" certificate in your Keychain (for direct distribution outside the App Store)
  - App Store Connect API key stored as a notarytool keychain profile (see below)

Set up the notarytool keychain profile once (substitute your own values):

```bash
xcrun notarytool store-credentials "my-notary-profile" \
  --key ~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8 \
  --key-id <KEY_ID> \
  --issuer <ISSUER_UUID>
```

### Setup

`CMakeUserPresets.json` is gitignored. Create it at the repo root with your local signing details:

```json
{
    "version": 6,
    "configurePresets": [
        {
            "name": "macos-release-local",
            "inherits": "macos-release",
            "environment": {
                "QT_MACOS_ROOT": "/path/to/Qt/6.10.2/macos",
                "MACOS_NOTARY_KEYCHAIN_PROFILE": "<profile name from store-credentials>",
                "MACOS_APP_SIGN_IDENTITY": "Developer ID Application: Your Name (TEAMID)",
                "MACOS_DMG_SIGN_IDENTITY": "Developer ID Application: Your Name (TEAMID)"
            },
            "cacheVariables": {
                "QTQUICKTEMPLATE_APPLE_BUNDLE_IDENTIFIER": "com.example.yourapp"
            }
        }
    ],
    "buildPresets": [
        {
            "name": "macos-app-local",
            "inherits": "macos-app",
            "configurePreset": "macos-release-local"
        },
        {
            "name": "macos-distributable-local",
            "inherits": "macos-distributable",
            "configurePreset": "macos-release-local"
        }
    ]
}
```

**Two ways to set environment variables:**

1. **`.env.local`** (recommended) — set `QT_MACOS_ROOT`, `MACOS_NOTARY_KEYCHAIN_PROFILE`, `MACOS_APP_SIGN_IDENTITY`, `MACOS_DMG_SIGN_IDENTITY` in `.env.local`. Run `./tools/configure-env.sh` to interactively configure.
2. **`CMakeUserPresets.json`** — set these values in the preset's `environment` block as shown above.

Both approaches work; `.env.local` is simpler for single-machine setups, while `CMakeUserPresets.json` enables per-preset configurations.

### Full pipeline (one command after first configure)

```bash
# Configure (once, or after CMake changes)
./tools/run cmake --preset macos-release-local

# Build → deploy Qt → sign → DMG → notarize → staple → verify
./tools/run cmake --build --preset macos-distributable-local
```

Output DMG: `build/Qt_6_10_2_for_macOS/QtQuickTemplate-<version>-macOS.dmg`

### Individual targets

| Target | What it does |
|--------|-------------|
| `MacDeployQt` | Runs `macdeployqt` to bundle Qt frameworks and optionally signs the app bundle |
| `DMG` | Runs CPack DragNDrop to create a `.dmg`, then signs it with Developer ID |
| `NotarizeMacOS` | Submits the DMG to Apple's notary service via `xcrun notarytool --wait`, then staples the ticket to both the DMG and the app bundle |
| `VerifyMacOSPackage` | Verifies codesign, Gatekeeper acceptance, and stapler validation of the notarized artifacts |
| `ReleaseDistributableMacOS` | Meta-target: runs all of the above in order |

To build without packaging:

```bash
./tools/run cmake --build --preset macos-app-local
```

### CMake cache variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `QTQUICKTEMPLATE_MACOS_APP_SIGN_IDENTITY` | Developer ID for signing the app bundle via macdeployqt | (from `MACOS_APP_SIGN_IDENTITY` env) |
| `QTQUICKTEMPLATE_MACOS_DMG_SIGN_IDENTITY` | Developer ID for signing the DMG | (from `MACOS_DMG_SIGN_IDENTITY` env) |
| `QTQUICKTEMPLATE_MACOS_NOTARY_KEYCHAIN_PROFILE` | Keychain profile name for `xcrun notarytool` | (from `MACOS_NOTARY_KEYCHAIN_PROFILE` env) |
| `QTQUICKTEMPLATE_APPLE_BUNDLE_IDENTIFIER` | Bundle identifier | `dev.crowell.qtquicktemplate` |
| `QTQUICKTEMPLATE_MACOS_USE_MACDEPLOYQT` | Enable/disable macdeployqt deployment step | `ON` |

> **Note:** Signing is optional — if identities are left empty, macdeployqt runs unsigned and DMG signing is skipped. Notarization requires a signed app and DMG, so `MACOS_APP_SIGN_IDENTITY` and `MACOS_DMG_SIGN_IDENTITY` must be set for the full pipeline to succeed.

---

## macOS — App Store distribution: build, archive, export, verify, upload (PKG)

The Mac App Store pipeline uses the Xcode generator (separate build directory from the DMG pipeline). The full chain — build → archive → export signed `.pkg` → verify → upload to App Store Connect — runs with a single CMake build preset.

### Prerequisites

- **Xcode** with command-line tools
- **Qt 6.10+** for macOS (e.g. `~/Qt/6.10.2/macos`)
- An **Apple Developer** account with:
  - `Apple Distribution` certificate in your Keychain (the Mac App Store signing identity — different from the `Developer ID Application` cert used for DMG distribution)
  - App Store Connect API key (`.p8` file) at `~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8`
  - Your app record created in App Store Connect

### Setup

`CMakeUserPresets.json` is gitignored. Add the following preset to your local copy at the repo root:

```json
{
    "version": 6,
    "configurePresets": [
        {
            "name": "macos-appstore-local",
            "inherits": "macos-appstore",
            "environment": {
                "QT_MACOS_ROOT": "/path/to/Qt/6.10.2/macos",
                "APPLE_DEVELOPMENT_TEAM": "<YOUR_TEAM_ID>",
                "ASC_API_KEY_ID": "<YOUR_ASC_API_KEY_ID>",
                "ASC_API_ISSUER_ID": "<YOUR_ASC_API_ISSUER_UUID>"
            },
            "cacheVariables": {
                "QTQUICKTEMPLATE_APPLE_BUNDLE_IDENTIFIER": "com.example.yourapp"
            }
        }
    ],
    "buildPresets": [
        {
            "name": "macos-appstore-app-local",
            "inherits": "macos-appstore-app",
            "configurePreset": "macos-appstore-local"
        },
        {
            "name": "macos-appstore-distributable-local",
            "inherits": "macos-appstore-distributable",
            "configurePreset": "macos-appstore-local"
        }
    ]
}
```

**Two ways to set environment variables:**

1. **`.env.local`** (recommended) — set `QT_MACOS_ROOT`, `APPLE_DEVELOPMENT_TEAM`, `ASC_API_KEY_ID`, `ASC_API_ISSUER_ID` in `.env.local`. Run `./tools/configure-env.sh` to interactively configure.
2. **`CMakeUserPresets.json`** — set these values in the preset's `environment` block as shown above.

Both approaches work; `.env.local` is simpler for single-machine setups, while `CMakeUserPresets.json` enables per-preset configurations.

### Full pipeline (one command after first configure)

```bash
# Configure (once, or after CMake changes)
./tools/run cmake --preset macos-appstore-local

# Build → archive → export PKG → verify → upload to App Store Connect
./tools/run cmake --build --preset macos-appstore-distributable-local
```

The exported `.pkg` lands in `build/Qt_6_10_2_for_macOS_AppStore/macos/export/`.

### Individual targets

| Target | What it does |
|--------|-------------|
| `MacAppStoreArchive` | Runs `xcodebuild archive` with the `Apple Distribution` identity to produce an `.xcarchive` |
| `MacExportPkg` | Runs `xcodebuild -exportArchive` to produce a signed `.pkg` from the archive |
| `VerifyMacPkg` | Verifies that a `.pkg` file exists in the export directory |
| `MacUploadASC` | Uploads the `.pkg` to App Store Connect using `xcrun altool --upload-app` with ASC API key auth |
| `ReleaseDistributableMacOSAppStore` | Meta-target: runs all of the above in order |

To build without packaging:

```bash
./tools/run cmake --build --preset macos-appstore-app-local
```

### CMake cache variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM` | Apple team ID used during archive and export | (from `APPLE_DEVELOPMENT_TEAM` env) |
| `QTQUICKTEMPLATE_MACOS_APP_STORE_PROVISIONING_PROFILE` | Mac App Store Distribution provisioning profile name | (from `MACOS_APP_STORE_PROVISIONING_PROFILE` env) |
| `QTQUICKTEMPLATE_ASC_API_KEY_ID` | App Store Connect API key ID | (from `ASC_API_KEY_ID` env) |
| `QTQUICKTEMPLATE_ASC_API_ISSUER_ID` | App Store Connect API issuer UUID | (from `ASC_API_ISSUER_ID` env) |
| `QTQUICKTEMPLATE_APPLE_BUNDLE_IDENTIFIER` | Bundle identifier | `dev.crowell.qtquicktemplate` |
| `QTQUICKTEMPLATE_MACOS_APP_STORE_ARCHIVE_CONFIGURATION` | Build configuration for archive/export | `Release` |

> **Note:** The API key file must exist at `~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8` on the build machine — this is where `xcrun altool` looks for it automatically.

---

## QML modules & resource layout

This project intentionally **flattens QML resource paths** using `QT_RESOURCE_ALIAS` so that pages/components can be referenced by simple filenames (e.g. `Qt.resolvedUrl("Readme.qml")`) even if they live under `qml/pages/` in the source tree.

The `AppTheme` and `AppStyle` modules are located in the `libs/` directory.

Modules:
- `AppTheme` → `Theme.qml` singleton (located in `libs/apptheme/qml/`)
- `AppStyle` → custom controls style (depends on `AppTheme`, located in `libs/appstyle/qml/`)
- `QtQuickTemplate` → main application QML

---

## Documentation (QDoc)

If `qdoc` is available in your Qt installation, you'll get build targets:

- Generate app docs:
  ```bash
  ./tools/run cmake --build build --target docs
  ```

- Generate `helloworld` library docs:
  ```bash
  ./tools/run cmake --build build --target helloworld_docs
  ```

The main QDoc configuration lives in `doc/qtquicktemplate.qdocconf`.

---

## Discovering build targets (`help-targets`)

After configuring, run the built-in help target to see every custom target available for the current platform (plus Android, which always appears):

```bash
cmake --build <dir> --target help-targets
```

This prints a grouped, formatted summary of each target with its description, invocation command, and any required or optional CMake variables.

### All custom targets

The table below documents every custom target across all platforms. Only targets for the current platform (and Android) are actually created during configuration; the rest are silently skipped.

#### Linux

| Target | Description | Command |
|--------|-------------|---------|
| `AppImage` | Package the app as an AppImage using linuxdeploy | `cmake --build <dir> --target AppImage` |
| `ReleaseDistributableLinux` | Full Linux release pipeline (depends on AppImage) | `cmake --build <dir> --target ReleaseDistributableLinux` |

**Variables for `AppImage`:**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `GPG_KEY_ID` | No | _(empty)_ | GPG key ID for AppImage signing. If unset, no signing is performed. |
| `ENABLE_WAYLAND` | No | `ON` | Bundle the Qt Wayland platform plugin into the AppImage. |

#### macOS -- Direct Distribution (DMG)

| Target | Description | Command |
|--------|-------------|---------|
| `MacDeployQt` | Deploy Qt frameworks into the macOS app bundle | `cmake --build <dir> --target MacDeployQt` |
| `DMG` | Package the macOS app bundle into a signed DMG | `cmake --build <dir> --target DMG` |
| `NotarizeMacOS` | Submit DMG to Apple notary service and staple the ticket | `cmake --build <dir> --target NotarizeMacOS` |
| `VerifyMacOSPackage` | Verify codesign, spctl, and notarization of the DMG and app bundle | `cmake --build <dir> --target VerifyMacOSPackage` |
| `ReleaseDistributableMacOS` | Full macOS DMG pipeline (build -> deploy -> DMG -> notarize -> verify) | `cmake --build <dir> --target ReleaseDistributableMacOS` |

**Variables for DMG pipeline:**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `QTQUICKTEMPLATE_MACOS_DMG_SIGN_IDENTITY` | No | _(empty)_ | Signing identity for the DMG. |
| `QTQUICKTEMPLATE_MACOS_NOTARY_KEYCHAIN_PROFILE` | Yes (for notarization) | _(empty)_ | Keychain profile name for `xcrun notarytool`. |

#### macOS -- App Store (PKG)

| Target | Description | Command |
|--------|-------------|---------|
| `MacAppStoreArchive` | Archive macOS app for App Store distribution via xcodebuild | `cmake --build <dir> --target MacAppStoreArchive` |
| `MacExportPkg` | Export signed macOS PKG from xcarchive for App Store submission | `cmake --build <dir> --target MacExportPkg` |
| `VerifyMacPkg` | Verify exported macOS PKG output | `cmake --build <dir> --target VerifyMacPkg` |
| `MacUploadASC` | Upload signed macOS PKG to App Store Connect | `cmake --build <dir> --target MacUploadASC` |
| `ReleaseDistributableMacOSAppStore` | Full macOS App Store pipeline (archive -> export -> verify -> upload) | `cmake --build <dir> --target ReleaseDistributableMacOSAppStore` |

**Variables for App Store pipeline:**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM` | Yes | _(empty)_ | Apple development team ID (10-char). |
| `QTQUICKTEMPLATE_ASC_API_KEY_ID` | Yes (for upload) | _(empty)_ | App Store Connect API key ID. |
| `QTQUICKTEMPLATE_ASC_API_ISSUER_ID` | Yes (for upload) | _(empty)_ | App Store Connect API issuer UUID. |

#### iOS

| Target | Description | Command |
|--------|-------------|---------|
| `IOSArchive` | Archive iOS app for App Store distribution via xcodebuild | `cmake --build <dir> --target IOSArchive` |
| `IOSExportIPA` | Export signed iOS IPA from xcarchive for App Store submission | `cmake --build <dir> --target IOSExportIPA` |
| `VerifyIOSIPA` | Verify exported iOS IPA output | `cmake --build <dir> --target VerifyIOSIPA` |
| `IOSUploadASC` | Upload signed iOS IPA to App Store Connect | `cmake --build <dir> --target IOSUploadASC` |
| `ReleaseDistributableIOS` | Full iOS pipeline (archive -> export -> verify -> upload) | `cmake --build <dir> --target ReleaseDistributableIOS` |

**Variables for iOS pipeline:**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM` | Yes | _(empty)_ | Apple development team ID (10-char). |
| `QTQUICKTEMPLATE_ASC_API_KEY_ID` | Yes (for upload) | _(empty)_ | App Store Connect API key ID. |
| `QTQUICKTEMPLATE_ASC_API_ISSUER_ID` | Yes (for upload) | _(empty)_ | App Store Connect API issuer UUID. |

#### Android

Android targets always appear in `help-targets` output regardless of the current build platform.

| Target | Description | Command |
|--------|-------------|---------|
| `AndroidAAB` | Build unsigned Android release AAB via Gradle | `cmake --build <dir> --target AndroidAAB` |
| `SignAndroidAAB` | Sign Android release AAB via Gradle | `cmake --build <dir> --target SignAndroidAAB` |
| `AndroidAPK` | Build unsigned Android release APK via Gradle | `cmake --build <dir> --target AndroidAPK` |
| `VerifyAndroidAAB` | Verify Android release AAB signature via jarsigner | `cmake --build <dir> --target VerifyAndroidAAB` |
| `VerifyAndroidAPK` | Verify Android release APK signature via apksigner | `cmake --build <dir> --target VerifyAndroidAPK` |
| `UploadAndroidPlay` | Upload signed Android AAB to Google Play via Gradle | `cmake --build <dir> --target UploadAndroidPlay` |
| `ReleaseDistributableAndroid` | Full Android release pipeline (AAB + APK) | `cmake --build <dir> --target ReleaseDistributableAndroid` |

**Variables for Android pipeline:**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `QTQUICKTEMPLATE_ANDROID_KEYSTORE_PATH` | Yes (for signing) | _(empty)_ | Path to Android keystore file. |
| `QTQUICKTEMPLATE_ANDROID_KEYSTORE_PASSWORD` | Yes (for signing) | _(empty)_ | Keystore password. |
| `QTQUICKTEMPLATE_ANDROID_KEY_ALIAS` | Yes (for signing) | _(empty)_ | Key alias within the keystore. |
| `QTQUICKTEMPLATE_ANDROID_KEY_PASSWORD` | Yes (for signing) | _(empty)_ | Key password. |
| `QTQUICKTEMPLATE_ANDROID_PLAY_SERVICE_ACCOUNT_FILE` | Yes (for upload) | _(empty)_ | Path to Google Play service-account JSON. |
| `QTQUICKTEMPLATE_ANDROID_PLAY_TRACK` | No | `internal` | Google Play track (internal, alpha, beta, production). |
| `QTQUICKTEMPLATE_ANDROID_PLAY_RELEASE_STATUS` | No | `completed` | Release status (completed, draft, inProgress, halted). |

#### Utilities

| Target | Description | Command |
|--------|-------------|---------|
| `docs` | Generate project documentation with QDoc | `cmake --build <dir> --target docs` |
| `ReleaseDistributable` | Build all release distributables for the current platform | `cmake --build <dir> --target ReleaseDistributable` |
| `help-targets` | Print this help summary | `cmake --build <dir> --target help-targets` |

---

## Customizing this template

A quick checklist you'll almost certainly want to do:

- Rename the project: `project(QtQuickTemplate ...)` in `CMakeLists.txt`
- Update `app.setOrganizationName("YourOrganization")` and other branding strings in `main.cpp`
- Replace package identifiers:
  - Linux metainfo + icon id: `dev.crowell.qtquicktemplate`
  - macOS bundle id: `CFBundleIdentifier`
  - Android namespace/package
- Swap icons:
  - `platforms/windows/app.ico`
  - `platforms/macos/app.icns` (optional)
  - `platforms/linux/icons/*` (optional)
- Decide on a license and add a LICENSE file (some platform metadata currently contains placeholders)

---

## Style notes

See `libs/appstyle/README.md` for a deeper dive into the Theme/AppStyle approach and how the controls are overridden.

---

## Contributing

PRs welcome—keep changes small, keep the template sharp, and try not to introduce "magic" unless it removes more pain than it adds.

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
| `CLAUDE.md` | Claude Code |
| `AGENTS.md` | OpenAI Codex, OpenCode |
| `GEMINI.md` | Google Gemini CLI |
| `.github/copilot-instructions.md` | GitHub Copilot |
| `.junie/guidelines.md` | JetBrains Junie |

These files contain project architecture context, build commands, and conventions to help AI agents produce correct, idiomatic contributions. Each agent is encouraged to decompose complex tasks into focused subtasks and to read existing code before proposing modifications.
