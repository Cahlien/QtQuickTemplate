# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Summary

Cross-platform Qt 6 / Qt Quick (QML) application template. CMake build system targeting iOS, macOS, Android, Linux, and Windows. Requires Qt 6.10+, CMake 4.2.1+, C++23.

## Developer Environment

Run `./tools/bootstrap.sh` (macOS/Linux) or `.\tools\bootstrap.ps1` (Windows) to create an isolated virtual environment with cmake, conan, pytest, and all Python-based build/test tools at pinned versions. The scripts install [uv](https://docs.astral.sh/uv/) into a project-local `tools/` directory if needed. On Linux, `bootstrap.sh` also downloads the linuxdeploy AppImage toolchain (core, Qt plugin, AppImage plugin) for the host architecture. Both scripts install Google's bundletool for Android builds.

Key files:
- **`.python-version`** — pins CPython 3.14t (freethreaded); uv auto-downloads this interpreter
- **`pyproject.toml`** — workspace Python metadata and dependency declarations (cmake, conan, pytest, etc.)
- **`uv.lock`** — cross-platform lockfile; regenerate with `./tools/uv lock` after changing `pyproject.toml`
- **`tools/bootstrap.sh`** / **`tools/bootstrap.ps1`** — idempotent bootstrap scripts
- **`tools/uv`** — project-local uv binary (gitignored, installed by bootstrap)
- **`conanws.yml`** — Conan workspace definition; lists all monorepo products for `conan workspace install`
- **`conanfile.py`** — workspace version-authority recipe; records canonical versions for the single-version rule
- **`app/conanfile.py`** — app-level Conan recipe; declares which packages the app needs
- **`app/pyproject.toml`** — app-level pytest configuration (testpaths, markers, addopts)

After bootstrapping, prefix build/test commands with `./tools/uv run` (e.g. `./tools/uv run cmake --preset <name>`) or activate the venv directly (`source .venv/bin/activate`).

## Conan Workspace

C++ dependencies are managed via Conan 2. The workspace (`conanws.yml`) lists every product in the monorepo; `conanfile.py` at the workspace root is the single-version-rule authority for canonical dependency versions.

```bash
# Install dependencies for all workspace products
./tools/uv run conan workspace install conanws.yml

# Regenerate the lockfile after adding or bumping a dependency
./tools/uv run conan lock create conanws.yml

# Install dependencies for the app only (e.g. during iterative development)
./tools/uv run conan install app/ --build=missing
```

Single-version rule: when adding a dependency to `app/conanfile.py`, record the same version as a comment under `requirements()` in the root `conanfile.py` so the canonical version list is visible in one place. Regenerate `conan.lock` and commit it.

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

Root `CMakeLists.txt` is a workspace coordinator — it calls `configure_project()` then adds `app/` as the sole subdirectory. It declares `project(QtQuickTemplate)` without a `VERSION` (the version-bearing `project()` lives in `app/CMakeLists.txt`):

- **`cmake/ProjectSetup.cmake`** → `configure_project()`: compiler settings, Conan, Qt discovery, AUTOMOC
- **`app/CMakeLists.txt`** → declares `project(QtQuickTemplate VERSION 0.2.0)`, adds `app/libs/` subdirectory, includes `cmake/MainApp.cmake` and calls `configure_main_app()`: creates the executable, registers QML modules, platform sources, code signing, packaging targets

Deploy modules live in `cmake/deploy/` organized by platform subdirectory, with custom build targets that chain together:
- **iOS**: `IOSArchive → IOSExportIPA → VerifyIOSIPA → IOSUploadASC → ReleaseDistributableIOS`
- **macOS DMG**: `MacDeployQt → DMG → NotarizeMacOS → VerifyMacOSPackage → ReleaseDistributableMacOS`
- **macOS App Store**: `MacAppStoreArchive → MacExportPkg → VerifyMacPkg → MacUploadASC → ReleaseDistributableMacOSAppStore`
- **Linux**: `AppImage → ReleaseDistributableLinux`

Cross-platform modules at `cmake/deploy/` root:
- **`DeployPipelines.cmake`** — platform-conditional dispatcher; includes only the current platform's modules and provides `configure_deploy_pipelines(target)`
- **`VersionTarget.cmake`** — shared `add_version_target()` used by iOS and macOS builds
- **`ReleaseDistributables.cmake`** — meta-targets aggregating platform pipelines

Shared Apple helpers in `cmake/deploy/apple/`:
- **`XcodeExport.cmake`** — unified `xcodebuild -exportArchive` for iOS and macOS App Store
- **`ArtifactVerify.cmake`** / **`VerifyArtifact.cmake`** — unified artifact verification
- **`AscUpload.cmake`** / **`UploadAsc.cmake`** — unified App Store Connect upload
- **`AppleCodeSigning.cmake`** — release code signing configuration
- **`FindMacDeployQt.cmake`** — shared `find_macdeployqt()` used by macOS DMG and App Store builds

Platform-specific modules in `cmake/deploy/{ios,macos,android,linux}/`:
- **`ios/`**: `IOSBuild.cmake`, `IOSResources.cmake` (asset catalog + launch screen), `GenerateLaunchScreen.cmake`
- **`macos/`**: `MacOSBuild.cmake`, `MacOSPackage.cmake`, `MacOSSign.cmake`, `MacOSVerify.cmake`, `MacOSAppStoreBuild.cmake`, plus `-P` scripts
- **`android/`**: `AndroidBuild.cmake`, `AndroidVerify.cmake`, `AndroidUpload.cmake`, `AndroidVersion.cmake`, plus `-P` scripts
- **`linux/`**: `LinuxPackage.cmake`, plus `-P` scripts

All CMake modules use `include_guard(GLOBAL)`.

### Application Structure

The main application lives in `app/`, which contains its own `libs/` subdirectory for project-internal libraries.

- **Entry point**: `app/src/main/common/main.cpp` — creates QGuiApplication, sets AppStyle, loads `Main.qml`
- **Navigation**: C++ `NavigationController` singleton (`app/include/main/common/navigation/`) manages a back-stack of `(url, props, showChrome)` entries. QML drives a `Loader` from `currentUrl`/`currentProps`.
- **QML root**: `app/qml/Main.qml` — `ApplicationWindow` with adaptive portrait/landscape layouts
- **Organisms**: `app/qml/organisms/` — reusable composite components (Header, Footer, NavBar, NavigationStack)
- **Pages**: `app/qml/pages/` (Readme, StyleShowcase, License) with content components in `app/qml/pages/content/`
- **Layouts**: `app/qml/templates/` (AdaptiveLayout, MainPortraitLayout, MainLandscapeLayout)
- **Android back**: JNI glue in `app/src/main/android/` queues `NavigationController::pop()` onto the Qt thread

### QML Modules

Three QML modules, each a separate CMake target:
- **`dev.crowell.QtQuickTemplate`** — main app QML (files in `app/qml/`)
- **`dev.crowell.AppTheme`** — `Theme.qml` singleton with design tokens (colors, spacing, radii, typography)
- **`dev.crowell.AppStyle`** — custom Qt Quick Controls 2 style overriding Button, TextField, etc.

AppTheme and AppStyle link against Qt Private modules (`Qt6::QmlPrivate`, `Qt6::QuickPrivate`, `Qt6::QuickTemplates2Private`) for deep style customization. Both have the Qt type compiler enabled.

QML files use `QT_RESOURCE_ALIAS` for flattened resource paths (e.g., `app/qml/pages/Readme.qml` → `pages/Readme.qml`).

### Libraries

Libraries live in `app/libs/` — project-internal libraries are an architectural decision of `app/`, not the workspace. Libraries mirror the `app/` directory convention: C++ production code lives in `src/main/` and `include/main/`, tests live in a top-level `test/` directory (sibling to `src/`) with a `unit/cpp/` or `unit/qml/` hierarchy, and QML files in a top-level `qml/` directory.

Helper macros in `cmake/libs/LibraryCommon.cmake`:
- `add_portable_cpp_library()` / `add_portable_qt_library()` — static on iOS, shared elsewhere
- `apply_android_max_page_size()` — 16KB page alignment for Android

`app/libs/appstyle/tools/` contains Node.js developer utilities for palette extraction (`extract-crowell-palette.js`) and WCAG contrast validation (`validate-contrast.js`).

### Version Generation

`cmake/deploy/GenerateVersion.cmake` computes build number from `git rev-list --count HEAD`:
- iOS: generates `app/platforms/ios/version.xcconfig`
- Android: generates `app/platforms/android/version.properties`
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

Integration tests (Apple deploy pipeline, pytest, macOS only):

```bash
# -c app/pyproject.toml sets rootdir=app/ and loads app-level pytest config
./tools/uv run pytest -c app/pyproject.toml                 # 0 tests (all integration, excluded by default)
./tools/uv run pytest -c app/pyproject.toml -m integration  # all 48 integration tests
./tools/uv run pytest -c app/pyproject.toml -m ios          # iOS pipeline only
./tools/uv run pytest -c app/pyproject.toml -m macos_dmg    # macOS DMG pipeline only
./tools/uv run pytest -c app/pyproject.toml -m macos_appstore  # macOS App Store pipeline only
```

Test infrastructure:
- **`cmake/testing/TestingSetup.cmake`** — `configure_testing()`: option, `enable_testing()`, `find_package(Qt6 … Test QuickTest)`
- **`cmake/testing/TestTargets.cmake`** — `add_qt_test()` and `add_qt_quick_test()` helper functions

App-level tests:
- **`app/test/unit/cpp/`** — NavigationController C++ test runner + Q_OBJECT headers (`tst_cpp`)
- **`app/test/unit/qml/`** — Navigation QML test runner (`tst_qml_navigation`)
- **`app/test/integration/`** — Apple deploy pipeline integration tests (pytest, macOS only); verifies macOS DMG, macOS App Store PKG, and iOS IPA artifacts produced by the CMake deploy targets

Library tests (each library owns its own tests):
- **`app/libs/helloworld/test/unit/cpp/`** — HelloWorld C++ tests + Q_OBJECT headers (`tst_helloworld`)
- **`app/libs/apptheme/test/unit/qml/`** — AppTheme QML tests (`tst_qml_apptheme`)
- **`app/libs/appstyle/test/unit/qml/`** — AppStyle QML tests (`tst_qml_appstyle`)

## Key Conventions

- **C++23** project-wide (C++20 for the helloworld sample library demonstrating modules)
- **Qt minimum**: 6.10 — the FFmpeg static-linking workaround in `cmake/qt/QtProject.cmake` is specific to this version
- **Cache variable prefix**: all project-specific CMake cache variables use the `QTQUICKTEMPLATE_` prefix
- **Platform resources**: `app/platforms/{ios,macos,android,linux,windows}/` — Info.plists, entitlements, icons, manifests
- **QML directory is `app/qml/`** — used by macdeployqt's `-qmldir` flag; organized by atomic design level (atoms, molecules, organisms, templates, pages)

## Known Harmless Warnings

- `QT_CREATOR_SKIP_CONAN_SETUP` unused variable — set in user presets for Qt Creator compatibility
- `app-store` export method deprecated — should be `app-store-connect` in future Xcode versions
- CPack DragNDrop `install_name_tool` RPATH errors — harmless, macdeployqt already fixed RPATHs

## Task Delegation

For complex, multi-step tasks, delegate to specialized subagents:
- **Explore**: codebase search, file discovery, architecture questions — use before modifying unfamiliar code
- **Plan**: design implementation strategy for multi-file or cross-platform changes
- **Bash**: build commands, git operations, platform toolchain invocations
- **general-purpose**: multi-step research requiring investigation across many files
- **tech-lead-orchestrator**: cross-domain work spanning C++, CMake, Qt/QML, and platform-specific code

Prefer parallel subagent execution for independent tasks. CMake module changes may cascade across platforms — validate the full dependency chain before committing.
