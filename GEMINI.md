# GEMINI.md

Instructions for Gemini CLI and Gemini Code Assist when working in this repository.

## Project Summary

Cross-platform Qt 6 / Qt Quick (QML) application template. CMake build system targeting iOS, macOS, Android, Linux, and Windows. Requires Qt 6.10+, CMake 4.2.1+, C++23.

## Developer Environment

Run `./tools/bootstrap.sh` (macOS/Linux) or `.\tools\bootstrap.ps1` (Windows) to create an isolated virtual environment with cmake, conan, pytest, and all Python-based build/test tools at pinned versions. The scripts install [uv](https://docs.astral.sh/uv/) into a project-local `tools/` directory if needed. On Linux, `bootstrap.sh` also downloads the linuxdeploy AppImage toolchain (core, Qt plugin, AppImage plugin) for the host architecture. Both scripts install Google's bundletool for Android builds.

Key files:
- **`.python-version`** — pins CPython 3.14t (freethreaded); uv auto-downloads this interpreter
- **`pyproject.toml`** — project metadata and Python dependency declarations (cmake, conan, pytest, etc.)
- **`uv.lock`** — cross-platform lockfile; regenerate with `./tools/uv lock` after changing `pyproject.toml`
- **`tools/bootstrap.sh`** / **`tools/bootstrap.ps1`** — idempotent bootstrap scripts
- **`tools/uv`** — project-local uv binary (gitignored, installed by bootstrap)

After bootstrapping, prefix build/test commands with `./tools/uv run` (e.g. `./tools/uv run cmake --preset <name>`) or activate the venv directly (`source .venv/bin/activate`).

## Build Commands

All Apple presets require a `CMakeUserPresets.json` with signing credentials (gitignored). Presets ending in `-local` are user-defined overrides inheriting from the base presets in `CMakePresets.json`.

### macOS (Direct Distribution — DMG)
```bash
./tools/uv run cmake --preset macos-release-local          # Configure (Ninja)
./tools/uv run cmake --build --preset macos-app-local      # Build only
./tools/uv run cmake --build --preset macos-distributable-local  # Full: build → macdeployqt → DMG → notarize → staple → verify
```

### macOS (App Store — PKG)
```bash
./tools/uv run cmake --preset macos-appstore-local         # Configure (Xcode generator)
./tools/uv run cmake --build --preset macos-appstore-distributable-local  # Full: build → archive → export PKG → verify → upload ASC
```

### iOS (App Store)
```bash
./tools/uv run cmake --preset ios-release-local            # Configure (Xcode generator)
./tools/uv run cmake --build --preset ios-app-local        # Build only
./tools/uv run cmake --build --preset ios-distributable-local  # Full: build → archive → export IPA → verify → upload ASC
```

### Linux
```bash
./tools/uv run cmake -S . -B build/linux-release -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH=/path/to/Qt/6.x.y/gcc        # Configure (point to Qt SDK root)
./tools/uv run cmake --build build/linux-release     # Build only
./tools/uv run cmake --build build/linux-release --target AppImage  # Package as AppImage (unsigned)
```

To GPG-sign the AppImage, pass `-DGPG_KEY_ID=<key>` at configure time:
```bash
./tools/uv run cmake -S . -B build/linux-release -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH=/path/to/Qt/6.x.y/gcc \
  -DGPG_KEY_ID=<YOUR_KEY_ID>
```

### Android
Build via Qt Creator (recommended) or the generated Gradle project in `<build-dir>/android-build`.

## Architecture

### CMake Module Organization

Root `CMakeLists.txt` is a workspace coordinator — it declares `project(QtQuickTemplate)` without a version and adds `app/` as the sole subdirectory:

- **`cmake/ProjectSetup.cmake`** → `configure_project()`: compiler settings, Conan, Qt discovery, AUTOMOC
- **`app/CMakeLists.txt`** → declares `project(QtQuickTemplate VERSION 0.2.0)`, adds `app/libs/` subdirectory, includes `cmake/MainApp.cmake` and calls `configure_main_app()`: creates the executable, registers QML modules, platform sources, code signing, packaging targets

Deploy modules live in `cmake/deploy/` with consistent `{Platform}{Stage}.cmake` naming and define custom build targets that chain together:
- **iOS**: `IOSArchive → IOSExportIPA → VerifyIOSIPA → IOSUploadASC → ReleaseDistributableIOS`
- **macOS DMG**: `MacDeployQt → DMG → NotarizeMacOS → VerifyMacOSPackage → ReleaseDistributableMacOS`
- **macOS App Store**: `MacAppStoreArchive → MacExportPkg → VerifyMacPkg → MacUploadASC → ReleaseDistributableMacOSAppStore`
- **Linux**: `AppImage → ReleaseDistributableLinux`

Build-time `-P` scripts (version generation, notarization, verification, etc.) live alongside their deploy modules in `cmake/deploy/{platform}/` subdirectories; shared scripts live in `cmake/deploy/`.

All CMake modules use `include_guard(GLOBAL)`.

### Application Structure

- **Entry point**: `src/main/common/main.cpp` — creates QGuiApplication, sets AppStyle, loads `Main.qml`
- **Navigation**: C++ `NavigationController` singleton (`include/main/common/navigation/`) manages a back-stack of `(url, props, showChrome)` entries. QML drives a `Loader` from `currentUrl`/`currentProps`.
- **QML root**: `qml/Main.qml` — `ApplicationWindow` with adaptive portrait/landscape layouts
- **Organisms**: `qml/organisms/` — reusable composite components (Header, Footer, NavBar, NavigationStack)
- **Pages**: `qml/pages/` (Readme, StyleShowcase, License) with content components in `qml/pages/content/`
- **Layouts**: `qml/templates/` (AdaptiveLayout, MainPortraitLayout, MainLandscapeLayout)
- **Android back**: JNI glue in `src/main/android/` queues `NavigationController::pop()` onto the Qt thread

### QML Modules

Three QML modules, each a separate CMake target:
- **`dev.crowell.QtQuickTemplate`** — main app QML (files in `qml/`)
- **`dev.crowell.AppTheme`** — `Theme.qml` singleton with design tokens (colors, spacing, radii, typography)
- **`dev.crowell.AppStyle`** — custom Qt Quick Controls 2 style overriding Button, TextField, etc.

AppTheme and AppStyle link against Qt Private modules (`Qt6::QmlPrivate`, `Qt6::QuickPrivate`, `Qt6::QuickTemplates2Private`) for deep style customization. Both have the Qt type compiler enabled.

QML files use `QT_RESOURCE_ALIAS` for flattened resource paths (e.g., `qml/pages/Readme.qml` → `pages/Readme.qml`).

### Libraries

Libraries live in `app/libs/` — project-internal libraries are an architectural decision of `app/`, not the workspace. Libraries mirror the `app/` directory convention: C++ production code lives in `src/main/` and `include/main/`, test code in `src/test/` and `include/test/`, and QML files in a top-level `qml/` directory (sibling to `src/`).

Helper macros in `cmake/libs/LibraryCommon.cmake`:
- `add_portable_cpp_library()` / `add_portable_qt_library()` — static on iOS, shared elsewhere
- `apply_android_max_page_size()` — 16KB page alignment for Android

`app/libs/appstyle/tools/` contains Node.js developer utilities for palette extraction (`extract-crowell-palette.js`) and WCAG contrast validation (`validate-contrast.js`).

### Version Generation

`cmake/deploy/GenerateVersion.cmake` computes build number from `git rev-list --count HEAD`:
- iOS: generates `platforms/ios/version.xcconfig`
- Android: generates `platforms/android/version.properties`
- Format: `MARKETING_VERSION = 1.0`, `CURRENT_PROJECT_VERSION = 1.0.0.<commit_count>`

## Testing

C++ unit tests use Qt Test; QML tests use Qt Quick Test. Gated by `QTQUICKTEMPLATE_ENABLE_TESTING` (ON by default on desktop, OFF on iOS/Android).

```bash
# Configure (testing enabled by default on desktop)
./tools/uv run cmake --preset linux-release

# Build all (includes test targets)
./tools/uv run cmake --build build/Qt_6_10_2_for_Linux

# Run all tests via CTest preset
./tools/uv run ctest --preset linux-tests

# Run individual tests
./tools/uv run ctest --preset linux-tests -R tst_helloworld      # HelloWorld C++ tests
./tools/uv run ctest --preset linux-tests -R tst_cpp             # NavigationController C++ tests
./tools/uv run ctest --preset linux-tests -R tst_qml_apptheme    # AppTheme QML tests
./tools/uv run ctest --preset linux-tests -R tst_qml_appstyle    # AppStyle QML tests
./tools/uv run ctest --preset linux-tests -R tst_qml_navigation  # Navigation QML tests

# Disable testing (e.g. for mobile builds)
./tools/uv run cmake -S . -B build/no-tests -DQTQUICKTEMPLATE_ENABLE_TESTING=OFF
```

Test infrastructure:
- **`cmake/testing/TestingSetup.cmake`** — `configure_testing()`: option, `enable_testing()`, `find_package(Qt6 … Test QuickTest)`
- **`cmake/testing/TestTargets.cmake`** — `add_qt_test()` and `add_qt_quick_test()` helper functions

App-level tests:
- **`app/include/test/`** — test suite headers (declarations with Q_OBJECT)
- **`app/src/test/cpp/`** — NavigationController C++ test runner (`tst_cpp`)
- **`app/src/test/qml/`** — Navigation QML test runner (`tst_qml_navigation`)

Library tests (each library owns its own tests):
- **`app/libs/helloworld/src/test/cpp/`** — HelloWorld C++ tests (`tst_helloworld`)
- **`app/libs/apptheme/src/test/qml/`** — AppTheme QML tests (`tst_qml_apptheme`)
- **`app/libs/appstyle/src/test/qml/`** — AppStyle QML tests (`tst_qml_appstyle`)

## Key Conventions

- **C++23** project-wide (C++20 for the helloworld sample library demonstrating modules)
- **Qt minimum**: 6.10 — the FFmpeg static-linking workaround in `cmake/qt/QtProject.cmake` is specific to this version
- **Cache variable prefix**: all project-specific CMake cache variables use the `QTQUICKTEMPLATE_` prefix
- **Platform resources**: `platforms/{ios,macos,android,linux,windows}/` — Info.plists, entitlements, icons, manifests
- **QML directory is `qml/`** — used by macdeployqt's `-qmldir` flag; organized by atomic design level (atoms, molecules, organisms, templates, pages)

## Known Harmless Warnings

- `QT_CREATOR_SKIP_CONAN_SETUP` unused variable — set in user presets for Qt Creator compatibility
- `app-store` export method deprecated — should be `app-store-connect` in future Xcode versions
- CPack DragNDrop `install_name_tool` RPATH errors — harmless, macdeployqt already fixed RPATHs

## Task Delegation

When tackling complex, multi-step tasks, delegate to subagents and execute in parallel where possible:

- **Codebase exploration**: use search and file-reading tools (or a codebase investigator subagent) to understand existing patterns before proposing modifications
- **Cross-platform validation**: when changing CMake modules or C++ code, verify impact on each affected platform independently
- **Build and test**: run builds and tests as separate tasks; do not block investigation on build completion
- **Multi-domain changes**: for work spanning C++, CMake, Qt/QML, and platform-specific code, delegate each domain to a focused subagent

CMake module changes may cascade across platforms — validate the full dependency chain before committing.
