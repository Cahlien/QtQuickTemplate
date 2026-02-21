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

## iOS: archive, sign, export (App Store)

iOS App Store packaging is automated with Xcode generator targets:

- `IOSArchive`
- `IOSExportIPA`
- `VerifyIOSIPA`
- `ReleaseDistributableIOS`

Configure with Xcode and your Apple signing details:

```bash
cmake -S . -B build/ios-release -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DQTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM=<TEAM_ID> \
  -DQTQUICKTEMPLATE_APPLE_BUNDLE_IDENTIFIER=<BUNDLE_ID> \
  -DQTQUICKTEMPLATE_IOS_CODE_SIGN_STYLE=Automatic
```

Build an App Store-ready IPA:

```bash
cmake --build build/ios-release --target ReleaseDistributableIOS --config Release
```

Useful iOS CMake cache variables:

- `QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM` (required)
- `QTQUICKTEMPLATE_APPLE_BUNDLE_IDENTIFIER` (required)
- `QTQUICKTEMPLATE_IOS_CODE_SIGN_STYLE` (`Automatic` or `Manual`)
- `QTQUICKTEMPLATE_IOS_PROVISIONING_PROFILE_SPECIFIER` (required when using manual signing)
- `QTQUICKTEMPLATE_IOS_CODE_SIGN_IDENTITY` (optional, for example `Apple Distribution`)
- `QTQUICKTEMPLATE_IOS_ALLOW_PROVISIONING_UPDATES` (`ON`/`OFF`)
- `QTQUICKTEMPLATE_IOS_EXPORT_METHOD` (defaults to `app-store`)
- `QTQUICKTEMPLATE_IOS_ARCHIVE_PATH`
- `QTQUICKTEMPLATE_IOS_EXPORT_PATH`
- `QTQUICKTEMPLATE_IOS_EXPORT_OPTIONS_PLIST` (optional override)

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
  - Linux metainfo + icon id: `dev.crowell.app.template`
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
