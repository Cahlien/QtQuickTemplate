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
├── CMakeLists.txt
├── cmake/
│   ├── toolchain/
│   │   ├── CompilerSettings.cmake
│   │   ├── CxxModules.cmake
│   │   └── ClangScanDeps.cmake
│   └── libs/
│       └── LibraryCommon.cmake
├── conanfile.py
├── README.md
├── doc/
│   └── qtquicktemplate.qdocconf
├── include/
│   └── main/
│       └── common/
│           ├── app_info.h
│           ├── navigation/
│           │   └── navigation_controller.h
│           └── platform_init.h
├── libs/
│   ├── CMakeLists.txt                 # auto-adds child lib dirs
│   ├── appstyle/                      # custom Qt Quick Controls 2 style
│   │   ├── CMakeLists.txt
│   │   ├── README.md
│   │   └── qml/
│   │       ├── Button.qml
│   │       ├── CheckBox.qml
│   │       ├── ...
│   │       └── ToolTip.qml
│   ├── apptheme/                      # AppTheme singleton (design tokens)
│   │   ├── CMakeLists.txt
│   │   └── qml/
│   │       └── Theme.qml
│   └── helloworld/                    # sample C++20 module library
│       ├── CMakeLists.txt
│       ├── helloworld.cppm
│       ├── include/helloworld.h
│       ├── src/helloworld.cpp
│       └── doc/helloworld.qdocconf
├── platforms/
│   ├── android/                       # Qt Android package source (Gradle project + resources)
│   ├── ios/                           # Qt iOS platform-specific files
│   ├── linux/                         # .desktop + appstream metainfo templates
│   ├── macos/                         # Info.plist (bundle metadata)
│   └── windows/                       # .rc + manifest
├── qml/
│   ├── Main.qml
│   ├── organisms/
│   │   ├── Header.qml
│   │   ├── Footer.qml
│   │   └── NavBar.qml
│   ├── pages/
│   │   ├── License.qml
│   │   ├── Readme.qml
│   │   └── StyleShowcase.qml
│   └── templates/
│       ├── MainPortraitLayout.qml
│       └── MainLandscapeLayout.qml
└── src/
    └── main/
        ├── common/
        │   ├── main.cpp
        │   ├── app_info.cpp
        │   ├── navigation/
        │   │   └── navigation_controller.cpp
        │   └── platform_init_default.cpp
        └── android/
            ├── android_back_handler.cpp
            └── platform_init_android.cpp
```

---

## Build prerequisites

- **Qt 6.10+** (Core, Quick, QuickControls2, Qml)
- **CMake 3.28+**
- A C++23-capable compiler
- Optional module path requirements:
  - On supported non-Apple toolchains/generators, `helloworld` exports a C++20 module.
  - On Apple targets (and unsupported generators/toolchains), the app automatically uses the header/library path.
  - If using Clang with modules enabled, `clang-scan-deps` must be available (the project attempts to locate it automatically, including Android NDK hints).

Optional:
- **Conan 2** (the repo includes a basic `conanfile.py`)

---

## Linux: build, package, sign

### Build (local desktop binary)

```bash
cmake -S . -B build/linux-debug -DCMAKE_BUILD_TYPE=Debug
cmake --build build/linux-debug -j
```

For release builds:

```bash
cmake -S . -B build/linux-release -DCMAKE_BUILD_TYPE=Release
cmake --build build/linux-release -j
```

Run on Linux:

```bash
./build/linux-debug/appQtQuickTemplate
```

### Build with Conan (optional)

```bash
conan install . -s build_type=Debug --build=missing -of build/conan
cmake -S . -B build/linux-debug -DCMAKE_TOOLCHAIN_FILE=build/conan/conan_toolchain.cmake
cmake --build build/linux-debug -j
```

### Package (AppImage)

AppImage packaging is provided by `cmake/AppImage.cmake` and requires:

- `linuxdeploy`
- `linuxdeploy-plugin-qt`
- `linuxdeploy-plugin-appimage`

If they are installed in `~/applications`, `~/.local/bin`, or `/usr/local/bin`, CMake auto-detects them and enables the `AppImage` target.

```bash
cmake -S . -B build/linux-release -DCMAKE_BUILD_TYPE=Release
cmake --build build/linux-release --target AppImage -j
```

Output:

```text
build/linux-release/AppImageBuild/QtQuickTemplate-<version>-x86_64.AppImage
```

### Sign (AppImage)

AppImage signing is integrated into the same `AppImage` target. Provide a key ID at configure time:

```bash
cmake -S . -B build/linux-release \
  -DCMAKE_BUILD_TYPE=Release \
  -DGPG_KEY_ID=<YOUR_KEY_ID>
cmake --build build/linux-release --target AppImage -j
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

The `AuthKey_<KEY_ID>.p8` file must be in `~/.appstoreconnect/private_keys/` — the standard path that `altool` searches automatically.

### Full pipeline (one command after first configure)

```bash
# Configure (once, or after CMake changes)
cmake --preset ios-release-local

# Build → archive → sign → export IPA → verify → upload to App Store Connect
cmake --build --preset ios-distributable-local
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
cmake --build --preset ios-app-local
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

## macOS: build, deploy, sign, notarize, verify (DMG)

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

### Full pipeline (one command after first configure)

```bash
# Configure (once, or after CMake changes)
cmake --preset macos-release-local

# Build → deploy Qt → sign → DMG → notarize → staple → verify
cmake --build --preset macos-distributable-local
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
cmake --build --preset macos-app-local
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
  cmake --build build --target docs
  ```

- Generate `helloworld` library docs:
  ```bash
  cmake --build build --target helloworld_docs
  ```

The main QDoc configuration lives in `doc/qtquicktemplate.qdocconf`.

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
